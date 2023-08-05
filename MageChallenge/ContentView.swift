import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var ballPosition: CGPoint = .zero
    @State private var goalReached = false
    
    private let motionManager = CMMotionManager()
    private let diameter: CGFloat = 15
    private let mazeData: [[Int]] = [
        [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0],
        [0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1],
        [0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1],
        [0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1],
        [1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1],
        [1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1],
        [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1],
        [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1],
        [0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0],
        [0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0],
        [0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0],
        [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1],
        [1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
        [0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0],
        [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0],
        [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    ]


    private var blockSize: CGFloat {
        min(UIScreen.main.bounds.width / CGFloat(mazeData[0].count), UIScreen.main.bounds.height / CGFloat(mazeData.count))
    }
    private var goalPosition: CGPoint = .zero
    
    init() {
        // ゴールの位置を初期化
        goalPosition = findGoalPosition()
    }

    private func findGoalPosition() -> CGPoint {
        var goalRow = 0
        var goalColumn = 0

        for (row, rowData) in mazeData.enumerated() {
            for (column, value) in rowData.enumerated() {
                if value == 0 {
                    goalRow = row
                    goalColumn = column
                }
            }
        }

        return CGPoint(x: CGFloat(goalColumn) * blockSize + blockSize / 2, y: CGFloat(goalRow) * blockSize + blockSize / 2)
    }


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                // 迷路を表示
                let rows = mazeData.count
                let maxColumns = mazeData.reduce(0) { max($0, $1.count) }
                let blockSize = min(geometry.size.width / CGFloat(maxColumns), geometry.size.height / CGFloat(rows))
                let xOffset = (geometry.size.width - CGFloat(maxColumns) * blockSize) / 2
                let yOffset = (geometry.size.height - CGFloat(rows) * blockSize) / 2
                let verticalOffset = geometry.size.height - CGFloat(rows) * blockSize

                ForEach(0..<rows, id: \.self) { row in
                    let columns = mazeData[row].count
                    let padding = (maxColumns - columns) / 2
                    ForEach(0..<columns, id: \.self) { col in
                        Rectangle()
                            .fill((row, col) == (Int(goalPosition.y / blockSize), Int(goalPosition.x / blockSize)) ? Color.green : mazeData[row][col] == 0 ? Color.clear : Color.black)
                            .frame(width: blockSize, height: blockSize)
                            .position(x: xOffset + CGFloat(col + padding) * blockSize + blockSize / 2, y: yOffset + CGFloat(row) * blockSize + blockSize / 2 + verticalOffset)}
                }

                // ボールを表示
                Circle()
                    .frame(width: diameter, height: diameter)
                    .foregroundColor(.red)
                    .position(x: xOffset + ballPosition.x, y: yOffset + ballPosition.y + verticalOffset)
                    .onAppear {
                        // ボールの初期位置を迷路の通路（値が0の部分）の端にする
                        ballPosition = findStartPosition()

                        // モーションマネージャーを開始する
                        self.resumeAccelerometerUpdates(in: geometry, xOffset: xOffset, yOffset: yOffset)
                    }
                    .onDisappear {
                        // モーションマネージャーを停止する
                        motionManager.stopAccelerometerUpdates()
                    }
                    .alert(isPresented: $goalReached) {
                        Alert(title: Text("おめでとうございます！"), message: Text("ゴールに到達しました！"), dismissButton: .default(Text("OK")) {
                            // ボールの位置を初期位置に戻し、ゴール到達状態をリセット。
                            ballPosition = findStartPosition()
                            goalReached = false
                            //DispatchQueueを使ってアクセラロメーターアップデートを少し遅らせて再開。
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.resumeAccelerometerUpdates(in: geometry, xOffset: xOffset, yOffset: yOffset)
                            }
                        })
                    }
            }
            .ignoresSafeArea(edges: [.all])
  
        }
    }
    // ボールの初期位置を画面の端にする
    private func findStartPosition() -> CGPoint {
        let cornerPositions: [(row: Int, column: Int)] = [
            (0, 0),                                      // 左上
            (0, mazeData[0].count - 1),                  // 右上
            (mazeData.count - 1, 0),                     // 左下
            (mazeData.count - 1, mazeData[0].count - 1)  // 右下
        ]

        for cornerPosition in cornerPositions {
            let row = cornerPosition.row
            let column = cornerPosition.column
            if mazeData[row][column] == 0 {
                return CGPoint(x: CGFloat(column) * blockSize + blockSize / 2, y: CGFloat(row) * blockSize + blockSize / 2)
            }
        }

        // すべての角が壁である場合、最初の通路を探す
        for (row, rowData) in mazeData.enumerated() {
            for (column, value) in rowData.enumerated() {
                if value == 0 {
                    return CGPoint(x: CGFloat(column) * blockSize + blockSize / 2, y: CGFloat(row) * blockSize + blockSize / 2)
                }
            }
        }

        // デフォルトの位置を返す（すべてのセルが壁である場合）
        return .zero
    }

    private func updateBallPosition(with data: CMAccelerometerData?, in geometry: GeometryProxy, xOffset: CGFloat, yOffset: CGFloat) {
        guard let data = data else { return }
        
        // x軸とy軸の加速度を取得する
        let x = data.acceleration.x
        let y = data.acceleration.y

        // ボールの位置を更新する
        let newX = ballPosition.x + CGFloat(x * 10)
        let newY = ballPosition.y - CGFloat(y * 10)

        // 半径
        let radius = diameter / 2

        // 画面の外に出ないようにする
        if newX > radius && newX < geometry.size.width - radius - 2 * xOffset {
            ballPosition.x = newX
        }
        if newY > radius && newY < geometry.size.height - radius - 2 * yOffset {
            ballPosition.y = newY
        }

        // ゴールに到達したかチェックする
        if abs(ballPosition.x - goalPosition.x) < 10 && abs(ballPosition.y - goalPosition.y) < 10 {
            // ゴールに到達した場合、モーションマネージャーを停止する
            motionManager.stopAccelerometerUpdates()

            // ゴールに到達したときに `goalReached` を trueに設定。
            goalReached = true
        }
    }

    private func resumeAccelerometerUpdates(in geometry: GeometryProxy, xOffset: CGFloat, yOffset: CGFloat) {
        // モーションマネージャーを再開する
        motionManager.startAccelerometerUpdates(to: .main) { [self] data, _ in
            updateBallPosition(with: data, in: geometry, xOffset: xOffset, yOffset: yOffset)
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
