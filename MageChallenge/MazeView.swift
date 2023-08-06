//// MazeView.swift
//import SwiftUI
//
//struct MazeView: View {
//    let rows: Int
//    let maxColumns: Int // ここをmaxColumnsに変更
//    let blockSize: CGFloat
//    let xOffset: CGFloat
//    let yOffset: CGFloat
//    let verticalOffset: CGFloat
//    let goalPosition: CGPoint
//    let mazeData: [[Int]]
//
//    var body: some View {
//        ForEach(0..<rows, id: \.self) { row in
//            let columns = mazeData[row].count
//            let padding = (maxColumns - columns) / 2 // この行でmaxColumnsを使用
//            ForEach(0..<columns, id: \.self) { col in
//                Rectangle()
//                    .fill((row, col) == (Int(goalPosition.y / blockSize), Int(goalPosition.x / blockSize)) ? Color.green
//                            : mazeData[row][col] == 2 ? Color.yellow
//                            : mazeData[row][col] == 0 ? Color.clear : Color.black)
//                    .frame(width: blockSize, height: blockSize)
//                    .position(x: xOffset + CGFloat(col + padding) * blockSize + blockSize / 2, y: yOffset + CGFloat(row) * blockSize + blockSize / 2 + verticalOffset)
//            }
//        }
//    }
//}
