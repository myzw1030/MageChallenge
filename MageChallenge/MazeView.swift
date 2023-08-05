//MazeView.swift

import SwiftUI

struct MazeView: View {
    let mazeData: [[Int]]
    let blockSize: CGFloat
    let goalPosition: CGPoint

    var body: some View {
        let rows = mazeData.count
        let maxColumns = mazeData.reduce(0) { max($0, $1.count) }
        
        return ForEach(0..<rows, id: \.self) { row in
            let columns = mazeData[row].count
            let padding = (maxColumns - columns) / 2
            ForEach(0..<columns, id: \.self) { col in
                Rectangle()
                    .fill((row, col) == (Int(goalPosition.y / blockSize), Int(goalPosition.x / blockSize)) ? Color.green
                        : mazeData[row][col] == 2 ? Color.yellow
                        : mazeData[row][col] == 0 ? Color.clear : Color.black)
                    .frame(width: blockSize, height: blockSize)
                    .position(x: CGFloat(col + padding) * blockSize + blockSize / 2, y: CGFloat(row) * blockSize + blockSize / 2)
            }
        }
    }
}
