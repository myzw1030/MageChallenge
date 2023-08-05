import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var ballPosition: CGPoint = .zero
    private let motionManager = CMMotionManager()
    private let diameter: CGFloat = 50
    private let mazeData: [[Int]] = [
        [0, 1, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 0, 1, 0],
        [0, 0, 0, 1, 0, 1, 1],
        [0, 1, 1, 1, 0, 0, 1],
        [0, 0, 0, 0, 0, 1, 1],
        [0, 1, 0, 0, 0, 0, 1]
    ]
    private let blockSize: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                // 迷路を表示
                ForEach(0..<mazeData.count, id: \.self) { row in
                    ForEach(0..<mazeData[row].count, id: \.self) { col in
                        if mazeData[row][col] == 0 {
                            Color.clear
                        } else {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: blockSize, height: blockSize)
                                .position(x: CGFloat(col) * blockSize + blockSize / 2, y: CGFloat(row) * blockSize + blockSize / 2)
                        }
                    }
                }

                // ボールを表示
                Circle()
                    .frame(width: diameter, height: diameter)
                    .foregroundColor(.red)
                    .position(ballPosition)
                    .onAppear {
                        // ボールの初期位置を画面の中心にする
                        ballPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                        // モーションマネージャーを開始する
                        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
                            guard let data else { return }

                            // x軸とy軸の加速度を取得する
                            let x = data.acceleration.x
                            let y = data.acceleration.y

                            // ボールの位置を更新する
                            let newX = ballPosition.x + CGFloat(x * 10)
                            let newY = ballPosition.y - CGFloat(y * 10)

                            // 半径
                            let radius = diameter / 2

                            // 画面の外に出ないようにする
                            if newX > radius && newX < geometry.size.width - radius {
                                ballPosition.x = newX
                            }
                            if newY > radius && newY < geometry.size.height - radius {
                                ballPosition.y = newY
                            }
                        }
                    }
                    .onDisappear {
                        // モーションマネージャーを停止する
                        motionManager.stopAccelerometerUpdates()
                    }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
