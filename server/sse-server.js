const express = require('express')
const fs = require('fs')
const serveStatic = require('serve-static')
const { default: SseStream } = require('ssestream')

const tinyData = ''
const normalData =
    '{"choices": [{"delta": {"role": "assistant", "content": " newsSubscription.unsubscribe();\\n    res", "phase": "answer", "status": "typing"}}], "response_id": "c468cca7-521c-4a58-8e8c-5fb16d54d8a5", "usage": {"input_tokens": 27273, "output_tokens": 1829, "total_tokens": 29102, "output_tokens_details": {"reasoning_tokens": 197}}}'
const largeData =
    `{"timestamp":"2026-01-23T14:25:30Z","region":"us-east-1","nodes":[{"nodeId":"web-01","status":"healthy","cpuUsage":42.7,"memoryUsage":68.3,"diskUsage":55.1,"latencyMs":48,"activeConnections":1243,"lastHeartbeat":"2026-01-23T14:25:29Z"},{"nodeId":"web-02","status":"degraded","cpuUsage":92.1,"memoryUsage":89.5,"diskUsage":70.2,"latencyMs":312,"activeConnections":2105,"lastHeartbeat":"2026-01-23T14:25:28Z","alerts":["high_cpu","high_latency"]},{"nodeId":"db-primary","status":"healthy","cpuUsage":35.0,"memoryUsage":76.8,"diskUsage":82.4,"latencyMs":5,"activeConnections":89,"lastHeartbeat":"2026-01-23T14:25:30Z"},{"nodeId":"cache-01","status":"unreachable","lastSeen":"2026-01-23T14:24:55Z","error":"connectiontimeout"}],"summary":{"totalNodes":4,"healthy":2,"degraded":1,"down":1}}`

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

const app = express()
app.use(serveStatic(__dirname))
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
const PORT = process.env.PORT || 9000
app.listen(PORT, '0.0.0.0', (err) => {
    if (err) {
        throw err
    }
    console.log(`server ready on http://0.0.0.0:${PORT}`)
})