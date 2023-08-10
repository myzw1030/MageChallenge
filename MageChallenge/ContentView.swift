import SwiftUI


struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("メイズチャレンジ")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                NavigationLink("ゲームを始める", destination: GameView())
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
//                NavigationLink("遊び方", nil)
//                    .padding()
//                    .background(Color.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
