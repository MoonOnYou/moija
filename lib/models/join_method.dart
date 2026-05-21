/// 모임 참가 방식. (docs/page/03_참가방식.png)
enum JoinMethod {
  approval('승인제', '신청을 받고 멤버를 골라 수락해요',
      ['누가 오는지 보고 결정', '신청자는 수락될 때만 다이아 차감']),
  firstCome('선착순', '자리가 있으면 바로 확정돼요',
      ['빠르게 모으고 싶을 때', '신청 즉시 확정 + 다이아 차감']);

  const JoinMethod(this.label, this.summary, this.bullets);

  final String label;
  final String summary;
  final List<String> bullets;
}
