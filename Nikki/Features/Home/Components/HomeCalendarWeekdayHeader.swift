import SwiftUI

/// カレンダーの曜日ヘッダ(日〜土)。曜日の記号は端末の言語に追従させる。
struct HomeCalendarWeekdayHeader: View {
    var body: some View {
        // 日グリッド(HomeCalendarDaysGrid)が日曜始まりで並べるため、ロケールの週の始まりによらず日曜から出す。
        // 英語の記号は "S" や "T" が重複するため、id は記号ではなく位置にする。
        let symbols = Calendar.display.veryShortStandaloneWeekdaySymbols
        HStack(spacing: 0) {
            ForEach(symbols.indices, id: \.self) { index in
                Text(symbols[index])
                    .font(.ink(11, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
    }
}

struct HomeCalendarWeekdayHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeCalendarWeekdayHeader()
            .padding()
            .background(Color.inkPaper)
    }
}
