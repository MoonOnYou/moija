/// 모임 참가 방식. (docs/page/03_참가방식.png)
enum JoinMethod {
  approval('승인제', '신청을 받고 멤버를 골라 수락해요'),
  firstCome('선착순', '자리가 있으면 바로 확정돼요');

  const JoinMethod(this.label, this.summary);

  final String label;
  final String summary;
}
