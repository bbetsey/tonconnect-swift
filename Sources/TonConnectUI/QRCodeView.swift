import SwiftUI
import CoreImage.CIFilterBuiltins

/// A stylized QR (as in @tonconnect/ui): circular dots instead of squares,
/// rounded "eyes" in the corners. CIQRCodeGenerator provides the module matrix,
/// we draw it ourselves via Canvas. The raster read orientation was verified
/// empirically (buffer row 0 = top of the image, no flip needed).
struct QRCodeView: View {
    let url: URL

    var body: some View {
        if let matrix = QRMatrix(text: url.absoluteString) {
            Canvas { context, size in
                Self.draw(matrix: matrix, context: &context, size: size)
            }
            .aspectRatio(1, contentMode: .fit)
        } else {
            Image(systemName: "xmark.circle") // unreachable: a URL always encodes
        }
    }

    private static func draw(matrix: QRMatrix, context: inout GraphicsContext, size: CGSize) {
        let n = matrix.size
        let cell = min(size.width, size.height) / CGFloat(n)
        let finderOrigins = [(0, 0), (n - 7, 0), (0, n - 7)]

        func inFinder(_ x: Int, _ y: Int) -> Bool {
            finderOrigins.contains { fx, fy in
                x >= fx && x < fx + 7 && y >= fy && y < fy + 7
            }
        }

        // Data modules — circles slightly smaller than the cell (eyes drawn separately).
        for y in 0..<n {
            for x in 0..<n where matrix[x, y] && !inFinder(x, y) {
                let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                                  width: cell, height: cell)
                    .insetBy(dx: cell * 0.11, dy: cell * 0.11)
                context.fill(Path(ellipseIn: rect), with: .color(.black))
            }
        }

        // The "eyes": a rounded 7×7 ring + a rounded 3×3 block.
        for (fx, fy) in finderOrigins {
            let outer = CGRect(x: CGFloat(fx) * cell + cell / 2,
                               y: CGFloat(fy) * cell + cell / 2,
                               width: cell * 6, height: cell * 6)
            context.stroke(Path(roundedRect: outer, cornerRadius: cell * 2),
                           with: .color(.black), lineWidth: cell)
            let inner = CGRect(x: CGFloat(fx + 2) * cell, y: CGFloat(fy + 2) * cell,
                               width: cell * 3, height: cell * 3)
            context.fill(Path(roundedRect: inner, cornerRadius: cell * 1.1),
                         with: .color(.black))
        }
    }
}

/// The QR's boolean module matrix: CIQRCodeGenerator renders 1 pixel = 1 module,
/// we read the raster and trim the quiet zone (the light border).
private struct QRMatrix {
    let size: Int
    private let dark: [Bool]

    subscript(x: Int, y: Int) -> Bool { dark[y * size + x] }

    init?(text: String) {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "H" // the logo covers the center — redundancy required
        guard let output = filter.outputImage,
              let cg = CIContext().createCGImage(output, from: output.extent) else { return nil }

        let w = cg.width
        var pixels = [UInt8](repeating: 0, count: w * w)
        guard let ctx = CGContext(data: &pixels, width: w, height: w,
                                  bitsPerComponent: 8, bytesPerRow: w,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: w))

        // Bounding box of the dark pixels — trims away the quiet zone.
        var minX = w, minY = w, maxX = -1, maxY = -1
        for y in 0..<w {
            for x in 0..<w where pixels[y * w + x] < 128 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX else { return nil }
        let side = maxX - minX + 1
        var grid = [Bool](repeating: false, count: side * side)
        for y in 0..<side {
            for x in 0..<side {
                grid[y * side + x] = pixels[(minY + y) * w + (minX + x)] < 128
            }
        }
        self.size = side
        self.dark = grid
    }
}
