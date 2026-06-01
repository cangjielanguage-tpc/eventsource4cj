/**
 * GZIP Compression/Decompression Utility
 * Uses stdx.compress.zlib for GZIP support
 */
package eventsource4cj.util

import stdx.compress.zlib.*
import std.collection.ArrayList
import std.io.*
import brotli4cj.*
import std.io.ByteBuffer

public class GzipUtil {
    // GZIP magic number for detection
    static let GZIP_MAGIC_1: UInt8 = 0x1f
    static let GZIP_MAGIC_2: UInt8 = 0x8b
    
    /// Compress data using GZIP format
    public static func compress(data: Array<UInt8>): Array<UInt8> {
        if (data.size == 0) {
            return []
        }
        
        // Create memory output stream to hold compressed data
        let memoryStream = MemoryStream()
        
        // Create compress output stream with GZIP format
        let compressStream = CompressOutputStream(memoryStream, wrap: GzipFormat, bufLen: 8192)
        
        // Write data to compress stream
        compressStream.write(data)
        compressStream.flush()
        compressStream.close()
        
        // Get compressed data from memory stream
        return memoryStream.toByteArray()
    }
    
    /// Decompress GZIP data
    public static func decompress(data: Array<UInt8>): Array<UInt8> {
        if (data.size < 18) {
            throw Exception("Invalid GZIP data: too short")
        }
        
        // Verify GZIP magic number
        if (!isGzip(data)) {
            throw Exception("Invalid GZIP data: bad magic number")
        }
        
        // Create memory input stream from compressed data
        let memoryStream = MemoryStream(data)
        
        // Create decompress input stream with GZIP format
        let decompressStream = DecompressInputStream(memoryStream, wrap: GzipFormat, bufLen: 8192)
        
        // Read decompressed data
        let result = ArrayList<UInt8>()
        let buffer = Array<UInt8>(8192, {_ => 0})
        
        while (true) {
            let readNum = decompressStream.read(buffer)
            if (readNum <= 0) {
                break
            }
            for (i in 0..readNum) {
                result.add(buffer[i])
            }
        }
        
        decompressStream.close()
        memoryStream.close()
        
        return result.toArray()
    }
    
    /// Check if data is GZIP compressed
    public static func isGzip(data: Array<UInt8>): Bool {
        if (data.size < 2) {
            return false
        }
        return data[0] == GZIP_MAGIC_1 && data[1] == GZIP_MAGIC_2
    }
    
    /// Compress string to GZIP bytes
    public static func compressString(str: String): Array<UInt8> {
        let bytes = str.toArray()
        return compress(bytes)
    }
    
    /// Decompress GZIP bytes to string
    public static func decompressToString(data: Array<UInt8>): String {
        let bytes = decompress(data)
        return String.fromUtf8(bytes)
    }
}

/// Memory stream implementation for in-memory byte operations
class MemoryStream <: InputStream & OutputStream {
    private var buffer: ArrayList<UInt8> = ArrayList<UInt8>()
    private var readPos: Int64 = 0
    private var closed: Bool = false
    
    public init() {
        this.buffer = ArrayList<UInt8>()
    }
    
    public init(data: Array<UInt8>) {
        this.buffer = ArrayList<UInt8>()
        for (b in data) {
            this.buffer.add(b)
        }
    }
    
    public func read(dest: Array<UInt8>): Int64 {
        if (closed || readPos >= buffer.size) {
            return 0
        }
        
        var count: Int64 = 0
        let destLen = dest.size
        while (readPos < buffer.size && count < destLen) {
            dest[count] = buffer[readPos]
            readPos++
            count++
        }
        return count
    }
    
    public func write(src: Array<UInt8>): Unit {
        if (closed) {
            return
        }
        for (b in src) {
            buffer.add(b)
        }
    }
    
    public func flush(): Unit {
        // No-op for memory stream
    }
    
    public func close(): Unit {
        closed = true
    }
    
    public func toByteArray(): Array<UInt8> {
        return buffer.toArray()
    }
    
    public func size(): Int64 {
        return buffer.size
    }
}

/**
 * Brotli Compression/Decompression Utility
 * Uses brotli4cj library for Brotli support
 */
public class BrotliUtil {
    /// Compress data using Brotli format
    public static func compress(data: Array<UInt8>): Array<UInt8> {
        if (data.size == 0) {
            return []
        }
        return Encoder.compress(data)
    }
    
    /// Compress data with quality parameter
    /// @param data Data to compress
    /// @param quality Compression quality (0-11, default 4)
    public static func compress(data: Array<UInt8>, quality: Int64): Array<UInt8> {
        if (data.size == 0) {
            return []
        }
        let params = Encoder_Parameters()
        params.setQuality(quality)
        return Encoder.compress(data, params)
    }
    
    /// Decompress Brotli data
    public static func decompress(data: Array<UInt8>): Array<UInt8> {
        if (data.size == 0) {
            return []
        }
        
        let input = ByteBuffer(data)
        let brotliInput = BrotliInputStream(input)
        
        let result = ArrayList<UInt8>()
        let buffer = Array<UInt8>(8192, {_ => 0})
        
        while (true) {
            let len = brotliInput.read(buffer)
            if (len <= 0) {
                break
            }
            for (i in 0..len) {
                result.add(buffer[i])
            }
        }
        
        return result.toArray()
    }
    
    /// Check if data might be Brotli compressed
    /// Brotli doesn't have a fixed magic number, but we can check for common patterns
    /// The first byte usually has specific bit patterns
    public static func isBrotli(data: Array<UInt8>): Bool {
        if (data.size < 2) {
            return false
        }
        // Brotli stream starts with WBITS (window bits) encoded in first byte
        // Common patterns: 0x8b, 0x0b, etc. depending on window size
        // For detection, we check if it's NOT gzip (avoid confusion)
        if (GzipUtil.isGzip(data)) {
            return false
        }
        // Brotli compressed data typically starts with certain patterns
        // This is a heuristic check - actual detection requires trying to decompress
        return data.size > 0
    }
    
    /// Compress string to Brotli bytes
    public static func compressString(str: String): Array<UInt8> {
        let bytes = str.toArray()
        return compress(bytes)
    }
    
    /// Decompress Brotli bytes to string
    public static func decompressToString(data: Array<UInt8>): String {
        let bytes = decompress(data)
        return String.fromUtf8(bytes)
    }
}
