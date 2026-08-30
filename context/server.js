#!/usr/bin/env node
import { readFileSync, readdirSync } from 'fs'
import { join } from 'path'
import { createInterface } from 'readline'

const CORPUS_DIR = process.env.CORPUS_DIR ?? '/corpus'

function buildIndex() {
  const chunks = []
  const files = readdirSync(CORPUS_DIR).filter(f => f.endsWith('.md')).sort()

  for (const file of files) {
    const content = readFileSync(join(CORPUS_DIR, file), 'utf8')
    let heading = ''
    let lines = []

    const flush = () => {
      const text = lines.join('\n').trim()
      if (text) chunks.push({ source: file, heading, text })
      lines = []
    }

    for (const line of content.split('\n')) {
      if (line.startsWith('#')) {
        flush()
        heading = line.replace(/^#+\s*/, '')
      } else {
        lines.push(line)
      }
    }
    flush()
  }

  return chunks
}

const index = buildIndex()

function search(query) {
  const terms = query.toLowerCase().split(/\W+/).filter(Boolean)
  return index
    .filter(c => terms.every(t => (c.heading + ' ' + c.text).toLowerCase().includes(t)))
    .slice(0, 5)
}

function send(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n')
}

const rl = createInterface({ input: process.stdin, terminal: false })

rl.on('line', raw => {
  if (!raw.trim()) return
  let msg
  try { msg = JSON.parse(raw) } catch { return }

  const { id, method, params } = msg

  if (method === 'initialize') {
    send({ jsonrpc: '2.0', id, result: {
      protocolVersion: '2024-11-05',
      capabilities: { tools: {} },
      serverInfo: { name: 'corpus-search', version: '1.0.0' }
    }})
  } else if (method === 'notifications/initialized') {
    // notification — no response
  } else if (method === 'tools/list') {
    send({ jsonrpc: '2.0', id, result: { tools: [{
      name: 'search_corpus',
      description: 'Search the organizational guidance corpus by keyword. Returns matching text chunks with source file and heading.',
      inputSchema: {
        type: 'object',
        properties: { query: { type: 'string', description: 'One or more keywords to search for' } },
        required: ['query']
      }
    }]}})
  } else if (method === 'tools/call') {
    const { name, arguments: args } = params
    if (name === 'search_corpus') {
      const results = search(args.query)
      const text = results.length
        ? results.map(r => `[${r.source} § ${r.heading}]\n${r.text}`).join('\n\n---\n\n')
        : 'No results found.'
      send({ jsonrpc: '2.0', id, result: { content: [{ type: 'text', text }] }})
    } else {
      send({ jsonrpc: '2.0', id, error: { code: -32601, message: 'Unknown tool' }})
    }
  } else if (id !== undefined) {
    send({ jsonrpc: '2.0', id, error: { code: -32601, message: 'Method not found' }})
  }
})
