const express = require('express')
const fs = require('fs')
const serveStatic = require('serve-static')
const { default: SseStream } = require('ssestream')

const app = express()
app.use(serveStatic(__dirname))
app.get('/sse/range/:count/:interval', (req, res) => {
    // console.log({
    //     method: req.method,
    //     url: req.url,
    //     headers: req.headers,
    //     params: req.params,
    //     query: req.query,
    //     body: req.body
    // });

    let count = Number(req.params.count)
    let interval = Number(req.params.interval)

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
        res.write(`event: range\ndata: ${count}\n\n`)
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