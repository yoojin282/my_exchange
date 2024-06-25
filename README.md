# 환율여행

환율정보 및 번역

## 실행방법
* 환율 API KEY 발급: [APILayer - Exchange Rates Data API](https://apilayer.com/marketplace/exchangerates_data-api) (월100회 제한)
* flutter run android --dart-define=API_KEY={API_KEY}

## 기능
* KRW (원) -> THB (바트), USB (달러)  환율 지원
* 번역 (한국어-> 태국어,영어) 지원

## 참고
* 이 앱은 개인 학습용으로 만들어 졌습니다.
* 환율정보는 APILayer의 Exchange Rates Data API 사용
* 번역은 구글번역사이트 크롤링 방식을 사용하기에 언제든 막힐수 있습니다.<br>[참고 (translator)](https://pub.dev/packages/translator)