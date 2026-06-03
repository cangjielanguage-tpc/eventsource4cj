const express = require('express')
const fs = require('fs')
const serveStatic = require('serve-static')
const { default: SseStream } = require('ssestream')
const compression = require('compression')
const zlib = require('zlib')

const tinyData = ''
const normalData =
    '{"choices": [{"delta": {"role": "assistant", "content": " newsSubscription.unsubscribe();\\n    res", "phase": "answer", "status": "typing"}}], "response_id": "c468cca7-521c-4a58-8e8c-5fb16d54d8a5", "usage": {"input_tokens": 27273, "output_tokens": 1829, "total_tokens": 29102, "output_tokens_details": {"reasoning_tokens": 197}}}'
const largeData =
    `{"timestamp":"2026-01-23T14:25:30Z","region":"us-east-1","nodes":[{"nodeId":"web-01","status":"healthy","cpuUsage":42.7,"memoryUsage":68.3,"diskUsage":55.1,"latencyMs":48,"activeConnections":1243,"lastHeartbeat":"2026-01-23T14:25:29Z"},{"nodeId":"web-02","status":"degraded","cpuUsage":92.1,"memoryUsage":89.5,"diskUsage":70.2,"latencyMs":312,"activeConnections":2105,"lastHeartbeat":"2026-01-23T14:25:28Z","alerts":["high_cpu","high_latency"]},{"nodeId":"db-primary","status":"healthy","cpuUsage":35.0,"memoryUsage":76.8,"diskUsage":82.4,"latencyMs":5,"activeConnections":89,"lastHeartbeat":"2026-01-23T14:25:30Z"},{"nodeId":"cache-01","status":"unreachable","lastSeen":"2026-01-23T14:24:55Z","error":"connectiontimeout"}],"summary":{"totalNodes":4,"healthy":2,"degraded":1,"down":1}}`
// AI streaming response payload — simulates ChatGPT/Claude style streaming tokens
// Each "delta" chunk is ~200 bytes with repetitive JSON structure, ideal for gzip compression testing
const aiStreamData = (chunkIndex) =>
    `{"choices":[{"delta":{"role":"assistant","content":"The implementation follows a systematic approach to resource management. Each component initializes its state machine through a configurable pipeline that processes incoming data in parallel streams. The synchronization layer ensures atomic operations across distributed nodes while maintaining consistency guarantees under concurrent access patterns.","phase":"answer","status":"typing","token_id":${chunkIndex}}},"response_id":"resp-ai-stream-${chunkIndex}","usage":{"input_tokens":1280,"output_tokens":${chunkIndex * 15},"total_tokens":${1280 + chunkIndex * 15},"output_tokens_details":{"reasoning_tokens":${chunkIndex > 5 ? chunkIndex * 3 : 0}}],"model":"claude-4-sonnet-20250514","created":${Date.now()}}`

function getData(datasize) {
    if (datasize == '0') {
        return tinyData
    }
    if (datasize == '1') {
        return normalData
    }
    if (datasize == '2') {
        return largeData
    }
    return tinyData
}

// Middleware to decompress GZIP request body
function gzipBodyParser(req, res, next) {
    const contentEncoding = req.headers['content-encoding']
    if (contentEncoding === 'gzip') {
        let chunks = []
        req.on('data', chunk => chunks.push(chunk))
        req.on('end', () => {
            const buffer = Buffer.concat(chunks)
            zlib.gunzip(buffer, (err, decompressed) => {
                if (err) {
                    console.error('GZIP decompression error:', err)
                    res.status(400).json({ error: 'Invalid GZIP data' })
                    return
                }
                req.body = decompressed
                req.decompressedBody = decompressed.toString('utf8')
                req._body = true // Mark body as already parsed to skip body-parser
                delete req.headers['content-encoding'] // Remove header to prevent body-parser from checking it
                next()
            })
        })
    } else {
        next()
    }
}

// Middleware to decompress Brotli request body
function brotliBodyParser(req, res, next) {
    const contentEncoding = req.headers['content-encoding']
    if (contentEncoding === 'br') {
        let chunks = []
        req.on('data', chunk => chunks.push(chunk))
        req.on('end', () => {
            const buffer = Buffer.concat(chunks)
            zlib.brotliDecompress(buffer, (err, decompressed) => {
                if (err) {
                    console.error('Brotli decompression error:', err)
                    res.status(400).json({ error: 'Invalid Brotli data' })
                    return
                }
                req.body = decompressed
                req.decompressedBody = decompressed.toString('utf8')
                req._body = true // Mark body as already parsed to skip body-parser
                delete req.headers['content-encoding'] // Remove header to prevent body-parser from checking it
                next()
            })
        })
    } else {
        next()
    }
}

// Combined compression body parser
function compressionBodyParser(req, res, next) {
    const contentEncoding = req.headers['content-encoding']
    if (contentEncoding === 'gzip') {
        gzipBodyParser(req, res, next)
    } else if (contentEncoding === 'br') {
        brotliBodyParser(req, res, next)
    } else {
        next()
    }
}

const app = express()
app.use(serveStatic(__dirname))
app.use(compression()) // Enable response compression
app.use(compressionBodyParser) // Handle GZIP and Brotli request bodies (must be before express.json())
app.use(express.json())
app.use(express.text())
app.use(express.raw({ type: 'application/octet-stream' }))

// POST SSE endpoint with body support
app.post('/sse/post/range/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('POST SSE connection:')
    console.log('  Headers:', JSON.stringify(req.headers, null, 2))
    console.log('  Body:', req.body)

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Transfer-Encoding', 'chunked');

    const pusher = setInterval(() => {
        if (count <= 0) {
            clearInterval(pusher)
            res.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) => `event: post-range\ndata: ${count}-${i + 1}|body:${JSON.stringify(req.body)}${data}\n\n`).join('');
        res.write(result)
        count--
    }, interval)
    res.on('close', () => {
        console.log('POST connection closed')
        clearInterval(pusher)
    })
})

// POST SSE endpoint with custom headers validation
app.post('/sse/post/secure/range/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('Secure POST SSE connection:')
    console.log('  Headers:', JSON.stringify(req.headers, null, 2))
    console.log('  Body:', req.body)

    const authToken = req.headers['x-auth-token']
    const clientId = req.headers['x-client-id']
    const apiKey = req.headers['x-api-key']

    console.log('  X-Auth-Token:', authToken)
    console.log('  X-Client-Id:', clientId)
    console.log('  X-Api-Key:', apiKey)

    if (!authToken || !clientId) {
        console.log('  Authentication failed: missing required headers')
        res.status(401).json({ error: 'Unauthorized: missing required headers (X-Auth-Token, X-Client-Id)' })
        return
    }

    if (apiKey && apiKey !== 'valid-api-key-12345') {
        console.log('  API Key validation failed')
        res.status(403).json({ error: 'Forbidden: invalid API key' })
        return
    }

    console.log('  Authentication successful')

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Transfer-Encoding', 'chunked');

    const pusher = setInterval(() => {
        if (count <= 0) {
            clearInterval(pusher)
            res.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) => `event: post-secure-range\ndata: ${count}-${i + 1}|client:${clientId}|body:${JSON.stringify(req.body)}${data}\n\n`).join('');
        res.write(result)
        count--
    }, interval)
    res.on('close', () => {
        console.log('Secure POST connection closed for client:', clientId)
        clearInterval(pusher)
    })
})

// SSE endpoint requiring custom headers validation
app.get('/sse/secure/range/:page/:count/:interval/:datasize?', (req, res) => {
    // Validate custom headers
    const authToken = req.headers['x-auth-token']
    const clientId = req.headers['x-client-id']
    const apiKey = req.headers['x-api-key']

    console.log('Secure SSE connection attempt:')
    console.log('  X-Auth-Token:', authToken)
    console.log('  X-Client-Id:', clientId)
    console.log('  X-Api-Key:', apiKey)

    // Simple validation example
    if (!authToken || !clientId) {
        console.log('  Authentication failed: missing required headers')
        res.status(401).json({ error: 'Unauthorized: missing required headers (X-Auth-Token, X-Client-Id)' })
        return
    }

    // Optional API Key validation
    if (apiKey && apiKey !== 'valid-api-key-12345') {
        console.log('  API Key validation failed')
        res.status(403).json({ error: 'Forbidden: invalid API key' })
        return
    }

    console.log('  Authentication successful')

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Transfer-Encoding', 'chunked');

    // Include client ID in data to verify identity
    const pusher = setInterval(() => {
        if (count <= 0) {
            clearInterval(pusher)
            res.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) => `event: secure-range\ndata: ${count}-${i + 1}|client:${clientId}|token:${authToken.substring(0, 8)}...${data}\n\n`).join('');
        res.write(result)
        count--
    }, interval)
    res.on('close', () => {
        console.log('Secure connection closed for client:', clientId)
        clearInterval(pusher)
    })
})

app.get('/sse/range/:page/:count/:interval/:datasize?', (req, res) => {
    // console.log({
    //     method: req.method,
    //     url: req.url,
    //     headers: req.headers,
    //     params: req.params,
    //     query: req.query,
    //     body: req.body
    // });

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Transfer-Encoding', 'chunked');

    const pusher = setInterval(() => {
        if (count <= 0) {
            clearInterval(pusher)
            res.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) => `event: range\ndata: ${count}-${i + 1}${data}\n\n`).join('');
        res.write(result)
        count--
    }, interval)
    res.on('close', () => {
        console.log('lost connection')
        clearInterval(pusher)
    })
})
app.get('/sse', (req, res) => {
    console.log('new connection')
    console.log('URL:', req.url)
    console.log('Headers:', JSON.stringify(req.headers, null, 2))
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Access-Control-Allow-Origin', '*')
    const sseStream = new SseStream(req)
    sseStream.pipe(res)
    const pusher = setInterval(() => {
        sseStream.write({
            event: 'server-time',
            data: new Date().toTimeString()
        })
    }, 2000)
    res.on('close', () => {
        console.log('lost connection')
        clearInterval(pusher)
        sseStream.unpipe(res)
    })
})

// GZIP compressed SSE response endpoint (for testing response decompression)
// This endpoint returns a complete GZIP compressed SSE response
app.get('/sse/gzip-response/test/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('GZIP Response Test:')
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])
    
    const acceptEncoding = req.headers['accept-encoding'] || ''
    
    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)
    
    // Generate SSE messages based on parameters
    const messages = []
    for (let i = 1; i <= count; i++) {
        const pageMessages = Array.from({ length: page }, (_, j) => 
            `event: gzip-test\ndata: ${i}-${j + 1} from GZIP compressed response${data}\n\n`
        ).join('')
        messages.push(pageMessages)
    }
    const sseContent = messages.join('')
    
    if (acceptEncoding.includes('gzip')) {
        // Return GZIP compressed response
        zlib.gzip(Buffer.from(sseContent), (err, compressed) => {
            if (err) {
                console.error('GZIP compression error:', err)
                res.status(500).send('Compression error')
                return
            }
            res.setHeader('Content-Type', 'text/event-stream')
            res.setHeader('Content-Encoding', 'gzip')
            res.setHeader('Access-Control-Allow-Origin', '*')
            res.send(compressed)
            console.log('  Sent GZIP compressed response, size:', compressed.length)
        })
    } else {
        // Return uncompressed response
        res.setHeader('Content-Type', 'text/event-stream')
        res.setHeader('Access-Control-Allow-Origin', '*')
        res.send(sseContent)
        console.log('  Sent uncompressed response')
    }
})

// GZIP compressed SSE POST endpoint (for testing both request and response compression)
app.post('/sse/gzip-response/post/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('GZIP Response POST Test:')
    console.log('  Content-Encoding:', req.headers['content-encoding'])
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])
    console.log('  Decompressed Body:', req.decompressedBody || 'N/A')
    
    const acceptEncoding = req.headers['accept-encoding'] || ''
    const requestBody = req.decompressedBody || JSON.stringify(req.body) || 'empty'
    
    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)
    
    // Generate SSE messages including request body info based on parameters
    const messages = []
    for (let i = 1; i <= count; i++) {
        const pageMessages = Array.from({ length: page }, (_, j) => 
            `event: gzip-post-test\ndata: ${i}-${j + 1}|body:${requestBody.substring(0, 50)}${data}\n\n`
        ).join('')
        messages.push(pageMessages)
    }
    const sseContent = messages.join('')
    
    if (acceptEncoding.includes('gzip')) {
        // Return GZIP compressed response
        zlib.gzip(Buffer.from(sseContent), (err, compressed) => {
            if (err) {
                console.error('GZIP compression error:', err)
                res.status(500).send('Compression error')
                return
            }
            res.setHeader('Content-Type', 'text/event-stream')
            res.setHeader('Content-Encoding', 'gzip')
            res.setHeader('Access-Control-Allow-Origin', '*')
            res.send(compressed)
            console.log('  Sent GZIP compressed response, size:', compressed.length)
        })
    } else {
        // Return uncompressed response
        res.setHeader('Content-Type', 'text/event-stream')
        res.setHeader('Access-Control-Allow-Origin', '*')
        res.send(sseContent)
        console.log('  Sent uncompressed response')
    }
})

// ============== Brotli SSE Endpoints ==============

// Brotli compressed SSE response endpoint (for testing response decompression)
// This endpoint returns a complete Brotli compressed SSE response
app.get('/sse/brotli-response/test/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('Brotli Response Test:')
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])
    
    const acceptEncoding = req.headers['accept-encoding'] || ''
    
    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)
    
    // Generate SSE messages based on parameters
    const messages = []
    for (let i = 1; i <= count; i++) {
        const pageMessages = Array.from({ length: page }, (_, j) => 
            `event: brotli-test\ndata: ${i}-${j + 1} from Brotli compressed response${data}\n\n`
        ).join('')
        messages.push(pageMessages)
    }
    const sseContent = messages.join('')
    
    if (acceptEncoding.includes('br')) {
        // Return Brotli compressed response
        zlib.brotliCompress(Buffer.from(sseContent), (err, compressed) => {
            if (err) {
                console.error('Brotli compression error:', err)
                res.status(500).send('Compression error')
                return
            }
            res.setHeader('Content-Type', 'text/event-stream')
            res.setHeader('Content-Encoding', 'br')
            res.setHeader('Access-Control-Allow-Origin', '*')
            res.send(compressed)
            console.log('  Sent Brotli compressed response, size:', compressed.length)
        })
    } else {
        // Return uncompressed response
        res.setHeader('Content-Type', 'text/event-stream')
        res.setHeader('Access-Control-Allow-Origin', '*')
        res.send(sseContent)
        console.log('  Sent uncompressed response')
    }
})

// Brotli compressed SSE POST endpoint (for testing both request and response compression)
app.post('/sse/brotli-response/post/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('Brotli Response POST Test:')
    console.log('  Content-Encoding:', req.headers['content-encoding'])
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])
    console.log('  Decompressed Body:', req.decompressedBody || 'N/A')
    
    const acceptEncoding = req.headers['accept-encoding'] || ''
    const requestBody = req.decompressedBody || JSON.stringify(req.body) || 'empty'
    
    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)
    
    // Generate SSE messages including request body info based on parameters
    const messages = []
    for (let i = 1; i <= count; i++) {
        const pageMessages = Array.from({ length: page }, (_, j) => 
            `event: brotli-post-test\ndata: ${i}-${j + 1}|body:${requestBody.substring(0, 50)}${data}\n\n`
        ).join('')
        messages.push(pageMessages)
    }
    const sseContent = messages.join('')
    
    if (acceptEncoding.includes('br')) {
        // Return Brotli compressed response
        zlib.brotliCompress(Buffer.from(sseContent), (err, compressed) => {
            if (err) {
                console.error('Brotli compression error:', err)
                res.status(500).send('Compression error')
                return
            }
            res.setHeader('Content-Type', 'text/event-stream')
            res.setHeader('Content-Encoding', 'br')
            res.setHeader('Access-Control-Allow-Origin', '*')
            res.send(compressed)
            console.log('  Sent Brotli compressed response, size:', compressed.length)
        })
    } else {
        // Return uncompressed response
        res.setHeader('Content-Type', 'text/event-stream')
        res.setHeader('Access-Control-Allow-Origin', '*')
        res.send(sseContent)
        console.log('  Sent uncompressed response')
    }
})

// Streaming GZIP compressed SSE endpoint (for testing stream decompression)
// Unlike the bulk gzip endpoint, this streams gzip-compressed SSE messages one by one
app.get('/sse/gzip-stream/test/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('GZIP Stream Test:')
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])

    const acceptEncoding = req.headers['accept-encoding'] || ''
    if (!acceptEncoding.includes('gzip')) {
        res.status(400).json({ error: 'Accept-Encoding: gzip required for this endpoint' })
        return
    }

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Content-Encoding', 'gzip')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')

    const gzipStream = zlib.createGzip()
    gzipStream.pipe(res)

    let remaining = count
    const pusher = setInterval(() => {
        if (remaining <= 0) {
            clearInterval(pusher)
            gzipStream.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) =>
            `event: gzip-stream\ndata: stream-msg-${remaining}-${i + 1}${data}\n\n`
        ).join('')
        gzipStream.write(result)
        remaining--
    }, interval)

    res.on('close', () => {
        console.log('GZIP stream connection closed')
        clearInterval(pusher)
        gzipStream.destroy()
    })
})

// AI streaming SSE endpoint with GZIP compression (simulates LLM streaming response)
// Generates large, repetitive JSON payloads that require multiple read() calls to decompress
// Total decompressed size exceeds 8KB buffer, forcing at least 2 effective read() calls
app.get('/sse/gzip-stream/ai/:page/:count/:interval', (req, res) => {
    console.log('GZIP AI Stream Test:')
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])

    const acceptEncoding = req.headers['accept-encoding'] || ''
    if (!acceptEncoding.includes('gzip')) {
        res.status(400).json({ error: 'Accept-Encoding: gzip required for this endpoint' })
        return
    }

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Content-Encoding', 'gzip')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')

    const gzipStream = zlib.createGzip()
    gzipStream.pipe(res)

    let remaining = count
    let chunkIndex = 1
    const pusher = setInterval(() => {
        if (remaining <= 0) {
            clearInterval(pusher)
            gzipStream.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) =>
            `event: ai-stream\ndata: ${aiStreamData(chunkIndex * page + i)}\n\n`
        ).join('')
        gzipStream.write(result)
        remaining--
        chunkIndex++
    }, interval)

    res.on('close', () => {
        console.log('GZIP AI stream connection closed')
        clearInterval(pusher)
        gzipStream.destroy()
    })
})

// Streaming Brotli compressed SSE endpoint (for testing stream decompression)
app.get('/sse/brotli-stream/test/:page/:count/:interval/:datasize?', (req, res) => {
    console.log('Brotli Stream Test:')
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])

    const acceptEncoding = req.headers['accept-encoding'] || ''
    if (!acceptEncoding.includes('br')) {
        res.status(400).json({ error: 'Accept-Encoding: br required for this endpoint' })
        return
    }

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Content-Encoding', 'br')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')

    const brotliStream = zlib.createBrotliCompress()
    brotliStream.pipe(res)

    let remaining = count
    const pusher = setInterval(() => {
        if (remaining <= 0) {
            clearInterval(pusher)
            brotliStream.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) =>
            `event: brotli-stream\ndata: stream-msg-${remaining}-${i + 1}${data}\n\n`
        ).join('')
        brotliStream.write(result)
        remaining--
    }, interval)

    res.on('close', () => {
        console.log('Brotli stream connection closed')
        clearInterval(pusher)
        brotliStream.destroy()
    })
})

// AI streaming SSE endpoint with Brotli compression (simulates LLM streaming response)
app.get('/sse/brotli-stream/ai/:page/:count/:interval', (req, res) => {
    console.log('Brotli AI Stream Test:')
    console.log('  Accept-Encoding:', req.headers['accept-encoding'])

    const acceptEncoding = req.headers['accept-encoding'] || ''
    if (!acceptEncoding.includes('br')) {
        res.status(400).json({ error: 'Accept-Encoding: br required for this endpoint' })
        return
    }

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Content-Encoding', 'br')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')

    const brotliStream = zlib.createBrotliCompress()
    brotliStream.pipe(res)

    let remaining = count
    let chunkIndex = 1
    const pusher = setInterval(() => {
        if (remaining <= 0) {
            clearInterval(pusher)
            brotliStream.end()
            return
        }
        const result = Array.from({ length: page }, (_, i) =>
            `event: ai-stream\ndata: ${aiStreamData(chunkIndex * page + i)}\n\n`
        ).join('')
        brotliStream.write(result)
        remaining--
        chunkIndex++
    }, interval)

    res.on('close', () => {
        console.log('Brotli AI stream connection closed')
        clearInterval(pusher)
        brotliStream.destroy()
    })
})

// SSE endpoint for testing message boundary edge cases (\n\n detection)
// Sends messages with comments, consecutive empty lines, and multiple messages in one chunk
app.get('/sse/boundary/test/:pattern', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Transfer-Encoding', 'chunked');

    const pattern = req.params.pattern

    let sseContent = ''
    if (pattern === '1') {
        // Pattern 1: comment + message + comment + message
        // Tests that comments are parsed correctly and \n\n boundary works after comments
        sseContent = ': this is a comment\n\nevent: boundary\ndata: msg1\n\n: another comment\n\nevent: boundary\ndata: msg2\n\n'
    } else if (pattern === '2') {
        // Pattern 2: multiple consecutive messages (3 messages back-to-back)
        // Tests that \n\n after \n\n does not incorrectly trigger extra handleMessage
        sseContent = 'event: boundary\ndata: msg1\n\nevent: boundary\ndata: msg2\n\nevent: boundary\ndata: msg3\n\n'
    } else if (pattern === '3') {
        // Pattern 3: message with id and retry fields, plus comment
        sseContent = 'id: 42\nretry: 500\nevent: boundary\ndata: msg-with-fields\n\n'
    } else if (pattern === '4') {
        // Pattern 4: multi-line data field (data appears on multiple lines)
        sseContent = 'event: boundary\ndata: line1\ndata: line2\ndata: line3\n\n'
    } else {
        sseContent = 'event: boundary\ndata: default\n\n'
    }

    // Write SSE content then close after a short delay to ensure chunked stream ends properly
    res.write(sseContent)
    setTimeout(() => { res.end() }, 100)
})

const PORT = process.env.PORT || 9000
app.listen(PORT, '0.0.0.0', (err) => {
    if (err) {
        throw err
    }
    console.log(`server ready on http://0.0.0.0:${PORT}`)
})