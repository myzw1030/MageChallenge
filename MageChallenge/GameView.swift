//GameView.swift

import SwiftUI
import CoreMotion

struct GameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var ballPosition: CGPoint = .zero
    @State private var goalReached = false
    @State private var ballHitWall = false // ゲームオーバーフラグ
    
    @State private var gameTime: Double = 0.0
    @State private var gameTimer: Timer? = nil
    @State private var gameStarted: Bool = false
    @State private var textSize: CGSize = CGSize(width: 0, height: 0)
    @State private var yOffset: CGFloat = 0
    
    
    enum GameAlert: Identifiable {
        case goalReached, ballHitWall
        
        var id: Int {
            switch self {
            case .goalReached:
                return 1
            case .ballHitWall:
                return 2
            }
        }
    }
    
    @State private var currentAlert: GameAlert?
    
    private let motionManager = CMMotionManager()
    private let diameter: CGFloat = 13
    
    private var blockSize: CGFloat {
        min(UIScreen.main.bounds.width / CGFloat(mazeData[0].count), UIScreen.main.bounds.height / CGFloat(mazeData.count))
    }
    private var goalPosition: CGPoint = .zero
    
    init() {
        // ゴールの位置を初期化
        goalPosition = findGoalPosition()
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            
            let rows = mazeData.count // 迷路の行数。
            let maxColumns = mazeData.reduce(0) { max($0, $1.count) } // 迷路の最大列数
            let blockSize = min(geometry.size.width / CGFloat(maxColumns), geometry.size.height / CGFloat(rows)) // マスのサイズ
            let xOffset = (geometry.size.width - CGFloat(maxColumns) * blockSize) / 2 // 迷路を画面の中央に配置するための水平方向のオフセット
            
            let mazeTotalHeight = CGFloat(rows) * blockSize
            let yOffset = (geometry.size.height - CGFloat(rows) * blockSize) / 2 // 画面の中央に迷路を配置
            
            VStack(spacing: 0) {
                // タイマー表示
                Spacer()
                Text("\(gameTime, specifier: "%.1f")")
                    .font(.largeTitle)
                    .foregroundColor(Color.white)
                //                    .background(Color.blue)
                    .padding(0)
                
                
                ZStack {
                    Color.white
                        .frame(width: CGFloat(maxColumns) * blockSize, height: mazeTotalHeight)
                        .position(x: geometry.size.width / 2, y:  mazeTotalHeight / 2)
                    
                    // 迷路を表示
                    ForEach(0..<rows, id: \.self) { row in
                        let columns = mazeData[row].count
                        let padding = (maxColumns - columns) / 2
                        
                        ForEach(0..<columns, id: \.self) { col in
                            Rectangle()
                                .fill((row, col) == (Int(goalPosition.y / blockSize), Int(goalPosition.x / blockSize)) ? Color.green
                                      : mazeData[row][col] == 2 ? Color.yellow
                                      : mazeData[row][col] == 0 ? Color.clear : Color.black)
                                .frame(width: blockSize, height: blockSize)
                                .position(x: xOffset + CGFloat(col + padding) * blockSize + blockSize / 2, y: CGFloat(row) * blockSize + blockSize / 2)
                            
                        }
                    }
                    
                    // ボールを表示
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .foregroundColor(.red)
                        .position(x: xOffset + ballPosition.x, y: ballPosition.y)
                        .onAppear {
                            startMotionManager(geometry: geometry, xOffset: xOffset, yOffset: yOffset)
                        }
                        .onDisappear {
                            stopMotionManager()
                        }
                        .alert(item: $currentAlert) { alertType in
                            switch alertType {
                            case .goalReached:
                                return Alert(title: Text("おめでとうございます！\nゴールに到達しました！"), message: Text("もう一度やりますか？"), primaryButton: .default(Text("はい")) {
                                    // ボールの位置を初期位置に戻し、ゴール到達状態をリセット。
                                    ballPosition = findStartPosition()
                                    currentAlert = nil
                                    gameStarted = false // ゲームの再開準備
                                    //DispatchQueueを使ってアクセラロメーターアップデートを少し遅らせて再開。
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        self.resumeAccelerometerUpdates(in: geometry, xOffset: xOffset, yOffset: yOffset)
                                    }
                                }, secondaryButton: .destructive(Text("いいえ")) {
                                    // 「いいえ」を選んだ場合、初期画面に戻る
                                    dismiss()
                                })
                            case .ballHitWall:
                                return Alert(title: Text("ゲームオーバー"), message: Text("もう一度やりますか？"), primaryButton: .default(Text("はい")) {
                                    // ボールの位置を初期位置に戻す
                                    ballPosition = findStartPosition()
                                    currentAlert = nil
                                    gameStarted = false // ゲームの再開準備
                                    // モーションマネージャーを再開する
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        self.resumeAccelerometerUpdates(in: geometry, xOffset: xOffset, yOffset: yOffset)
                                    }
                                }, secondaryButton: .destructive(Text("いいえ")) {
                                    // 「いいえ」を選んだ場合、初期画面に戻る
                                    dismiss()
                                    
                                })
                            }
                        }
                }
                .frame(height: mazeTotalHeight)
                
            }
            
            
            .ignoresSafeArea(edges: [.all])
            .navigationBarBackButtonHidden(true)
            
        }
        .background(Color.black)
    }
    
    // ボールの初期位置を画面の端にする
    private func findStartPosition() -> CGPoint {
        for (row, rowData) in mazeData.enumerated() {
            for (column, value) in rowData.enumerated() {
                if value == 2 {
                    return CGPoint(x: CGFloat(column) * blockSize + blockSize / 2, y: CGFloat(row) * blockSize + blockSize / 2)
                }
            }
        }
        
        // 2が見つからない場合のデフォルトの位置
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
        
        let newCol = Int(newX / blockSize)
        let newRow = Int(newY / blockSize)
        let adjustedRadius = radius - 1.7
        
        let rightCol = min(Int((newX + adjustedRadius) / blockSize), mazeData[0].count - 1)
        let leftCol = max(Int((newX - adjustedRadius) / blockSize), 0)
        let topRow = max(Int((newY - adjustedRadius) / blockSize), 0)
        let bottomRow = min(Int((newY + adjustedRadius) / blockSize), mazeData.count - 1)
        
        if mazeData[newRow][newCol] == 1 ||
            mazeData[topRow][newCol] == 1 ||
            mazeData[bottomRow][newCol] == 1 ||
            mazeData[newRow][leftCol] == 1 ||
            mazeData[newRow][rightCol] == 1 ||
            mazeData[topRow][leftCol] == 1 ||
            mazeData[topRow][rightCol] == 1 ||
            mazeData[bottomRow][leftCol] == 1 ||
            mazeData[bottomRow][rightCol] == 1 {
            motionManager.stopAccelerometerUpdates()
            ballHitWall = true
            currentAlert = .ballHitWall
            stopTimer()
        } else {
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
                currentAlert = .goalReached
                stopTimer()
            }
            
            if !gameStarted {
                startTimer()
                gameStarted = true
            }
        }
    }
    
    private func resumeAccelerometerUpdates(in geometry: GeometryProxy, xOffset: CGFloat, yOffset: CGFloat) {
        // モーションマネージャーを再開する
        motionManager.startAccelerometerUpdates(to: .main) { [self] data, _ in
            updateBallPosition(with: data, in: geometry, xOffset: xOffset, yOffset: yOffset)
        }
    }
    
    // ゴールの位置
    private func findGoalPosition() -> CGPoint {
        let start = findStartPositionInMaze() // スタート位置を初期位置とする
        var visited = Array(repeating: Array(repeating: false, count: mazeData[0].count), count: mazeData.count)
        visited[start.0][start.1] = true
        
        let longestPath = dfs(start: start, visited: &visited, currentPath: [start])
        let goal = longestPath.last! // 最も遠い点がゴール
        
        return CGPoint(x: CGFloat(goal.1) * blockSize + blockSize / 2, y: CGFloat(goal.0) * blockSize + blockSize / 2)
    }
    
    private func findStartPositionInMaze() -> (Int, Int) {
        for (row, rowData) in mazeData.enumerated() {
            for (column, value) in rowData.enumerated() {
                if value == 2 {
                    return (row, column)
                }
            }
        }
        
        // デフォルトのスタート位置は(0, 0)
        return (0, 0)
    }
    
    // 深さ優先探索（DFS）を実装
    private func dfs(start: (Int, Int), visited: inout [[Bool]], currentPath: [(Int, Int)]) -> [(Int, Int)] {
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        var longestPath = currentPath
        
        for direction in directions {
            let newRow = start.0 + direction.0
            let newCol = start.1 + direction.1
            
            // 範囲内か、まだ訪れていない通路か確認
            if newRow >= 0 && newRow < mazeData.count && newCol >= 0 && newCol < mazeData[0].count && mazeData[newRow][newCol] == 0 && !visited[newRow][newCol] {
                visited[newRow][newCol] = true
                let newPath = dfs(start: (newRow, newCol), visited: &visited, currentPath: currentPath + [(newRow, newCol)])
                
                // 最も長い経路を更新
                if newPath.count > longestPath.count {
                    longestPath = newPath
                }
            }
        }
        
        return longestPath
    }
    
    private func startMotionManager(geometry: GeometryProxy, xOffset: CGFloat, yOffset: CGFloat) {
        // ボールの初期位置を迷路の通路（値が0の部分）の端にする
        ballPosition = findStartPosition()
        
        // モーションマネージャーを開始する
        self.resumeAccelerometerUpdates(in: geometry, xOffset: xOffset, yOffset: yOffset)
    }
    
    private func stopMotionManager() {
        // モーションマネージャーを停止する
        motionManager.stopAccelerometerUpdates()
    }
    
    private func startTimer() {
        gameTime = 0.0 // タイマーをリセット
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            gameTime += 0.1
        }
    }
    
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
