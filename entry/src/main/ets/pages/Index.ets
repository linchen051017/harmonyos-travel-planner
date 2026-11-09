import { http } from '@kit.NetworkKit';

interface Destination {
  id: string;
  name: string;
  region: string;
  category: string;
  slogan: string;
  symbol: string;
  color: string;
  latitude: number;
  longitude: number;
  outdoor: string[];
  indoor: string[];
  food: string;
}

interface TripRoute {
  city: Destination;
}

interface CurrentWeather {
  time: string;
  temperature_2m: number | null;
  weather_code: number | null;
}

interface DailyWeather {
  time: string[];
  temperature_2m_max: (number | null)[];
  temperature_2m_min: (number | null)[];
  precipitation_probability_max: (number | null)[];
}

interface ForecastResponse {
  current?: CurrentWeather;
  daily?: DailyWeather;
}

interface DayForecast {
  date: string;
  high: number;
  low: number;
  rain: number;
}

const DESTINATIONS: Destination[] = [
  {
    id: 'changsha', name: '长沙', region: '湖南 · 城市漫游', category: '城市',
    slogan: '在烟火气里遇见星城', symbol: '✦', color: '#166F68',
    latitude: 28.2282, longitude: 112.9388,
    outdoor: ['橘子洲江畔漫步', '岳麓山观景', '湘江夜景'],
    indoor: ['湖南省博物馆', '简牍博物馆', '谢子龙影像艺术馆'],
    food: '坡子街寻找湘味'
  },
  {
    id: 'zhangjiajie', name: '张家界', region: '湖南 · 山水秘境', category: '山水',
    slogan: '把山峰写进旅行日记', symbol: '⌁', color: '#497D72',
    latitude: 29.1171, longitude: 110.4792,
    outdoor: ['武陵源观景', '金鞭溪徒步', '天门山远眺'],
    indoor: ['张家界博物馆', '土家风情展馆', '非遗体验空间'],
    food: '品尝土家三下锅'
  },
  {
    id: 'fenghuang', name: '凤凰古城', region: '湖南 · 古镇慢游', category: '古镇',
    slogan: '沿沱江寻找古城的光', symbol: '◈', color: '#A3694E',
    latitude: 27.9482, longitude: 109.5996,
    outdoor: ['沱江步道', '古城街巷漫游', '南华山远眺'],
    indoor: ['凤凰古城博物馆', '苗族文化展馆', '非遗手作体验'],
    food: '尝一份湘西酸汤'
  }
];

const CATEGORIES: string[] = ['全部', '城市', '山水', '古镇'];
const INTERESTS: string[] = ['自然', '人文', '美食'];
const PLAN_DAYS: number[] = [1, 2, 3];

@Component
struct DestinationCard {
  @Prop city: Destination;
  onOpen: () => void = () => {};

  build() {
    Column({ space: 16 }) {
      Row() {
        Text(this.city.region).fontSize(12).fontColor('#E8F5F0').layoutWeight(1)
        Text(this.city.symbol).fontSize(31).fontColor('#E8F5F0')
      }.width('100%')
      Column({ space: 7 }) {
        Text(this.city.name).fontSize(27).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text(this.city.slogan).fontSize(13).fontColor('#E8F5F0')
      }.width('100%').alignItems(HorizontalAlign.Start)
      Row() {
        Text('查看天气与行程').fontSize(13).fontColor('#FFFFFF').layoutWeight(1)
        Text('→').fontSize(20).fontColor('#FFFFFF')
      }.width('100%')
    }
    .width('100%').padding(20).borderRadius(22).backgroundColor(this.city.color)
    .alignItems(HorizontalAlign.Start).onClick(() => this.onOpen())
  }
}

@Component
struct TripDetailPage {
  @Prop route: TripRoute;
  @State loading: boolean = false;
  @State errorText: string = '';
  @State currentTemp: string = '—';
  @State weatherText: string = '等待更新';
  @State updateTime: string = '';
  @State forecast: DayForecast[] = [];
  @State selectedDays: number = 2;
  @State interest: string = '自然';

  aboutToAppear(): void {
    this.loadForecast();
  }

  private weatherName(code: number | null): string {
    if (code === null) { return '天气未知'; }
    if (code <= 1) { return '晴朗'; }
    if (code <= 3) { return '多云'; }
    if (code <= 48) { return '有雾'; }
    if (code <= 67) { return '有雨'; }
    if (code <= 77) { return '有雪'; }
    if (code <= 82) { return '阵雨'; }
    return '天气多变';
  }

  private async loadForecast(): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    this.errorText = '';
    this.currentTemp = '—';
    this.weatherText = '等待更新';
    this.updateTime = '';
    this.forecast = [];
    const city = this.route.city;
    const url = 'https://api.open-meteo.com/v1/forecast?latitude=' + city.latitude.toString() +
      '&longitude=' + city.longitude.toString() +
      '&current=temperature_2m,weather_code' +
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max' +
      '&forecast_days=3&timezone=Asia%2FShanghai';
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      if (response.responseCode !== 200) { throw new Error('HTTP ' + response.responseCode); }
      const data = JSON.parse(String(response.result)) as ForecastResponse;
      if (!data.current || !data.daily || !data.daily.time ||
          !data.daily.temperature_2m_max || !data.daily.temperature_2m_min ||
          !data.daily.precipitation_probability_max || data.daily.time.length === 0) {
        this.errorText = '暂无可用天气数据，请稍后重试';
        return;
      }
      this.currentTemp = data.current.temperature_2m === null ? '—' :
        data.current.temperature_2m.toFixed(0);
      this.weatherText = this.weatherName(data.current.weather_code);
      this.updateTime = data.current.time;
      const next: DayForecast[] = [];
      for (let i = 0; i < data.daily.time.length && i < 3; i++) {
        const high = data.daily.temperature_2m_max[i];
        const low = data.daily.temperature_2m_min[i];
        const rain = data.daily.precipitation_probability_max[i];
        if (high !== null && low !== null && rain !== null &&
            high !== undefined && low !== undefined && rain !== undefined) {
          next.push({ date: data.daily.time[i].slice(5), high: high, low: low, rain: rain });
        }
      }
      this.forecast = next;
      if (next.length === 0) { this.errorText = '暂无可用天气数据，请稍后重试'; }
    } catch (error) {
      this.currentTemp = '—';
      this.weatherText = '等待更新';
      this.updateTime = '';
      this.forecast = [];
      this.errorText = '天气加载失败，请检查网络后重试';
    } finally {
      request.destroy();
      this.loading = false;
    }
  }

  private planText(day: number): string {
    const city = this.route.city;
    const index = (day - 1) % 3;
    const rainy = this.forecast.length >= day && this.forecast[day - 1].rain >= 50;
    if (this.interest === '美食') {
      return city.food + ' → ' + (rainy ? city.indoor[index] : city.outdoor[index]);
    }
    if (this.interest === '人文' || rainy) {
      return city.indoor[index] + ' → ' + city.food;
    }
    return city.outdoor[index] + ' → ' + city.food;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 6 }) {
            Text(this.route.city.region).fontSize(13).fontColor('#64746D')
            Text(this.route.city.name + '旅行计划').fontSize(29)
              .fontWeight(FontWeight.Bold).fontColor('#18312C')
            Text(this.route.city.slogan).fontSize(14).fontColor('#64746D')
          }.width('100%').alignItems(HorizontalAlign.Start)

          Column({ space: 14 }) {
            Row() {
              Column({ space: 5 }) {
                Text('目的地天气').fontSize(13).fontColor('#DDEFE8')
                Text(this.currentTemp + '°  ' + this.weatherText).fontSize(28)
                  .fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('☀').fontSize(35).fontColor('#FFFFFF')
            }.width('100%')
            Text(this.updateTime === '' ? '数据来自 Open-Meteo' : '更新：' + this.updateTime)
              .fontSize(11).fontColor('#DDEFE8')
          }.width('100%').padding(20).borderRadius(22)
            .backgroundColor(this.route.city.color).alignItems(HorizontalAlign.Start)

          if (this.loading) {
            Row({ space: 9 }) {
              LoadingProgress().width(22).height(22)
              Text('正在获取目的地天气…').fontSize(14).fontColor('#64746D')
            }.width('100%').padding(16)
          } else if (this.errorText !== '') {
            Column({ space: 10 }) {
              Text(this.errorText).fontSize(14).fontColor('#A4483C')
              Button('重试').onClick(() => this.loadForecast()).backgroundColor('#166F68')
            }.width('100%').padding(18).borderRadius(18).backgroundColor('#FFFFFF')
          } else {
            Row() {
              Text('未来三日天气').fontSize(19).fontWeight(FontWeight.Bold)
                .fontColor('#18312C').layoutWeight(1)
              Text('刷新').fontSize(13).fontColor('#166F68').onClick(() => this.loadForecast())
            }.width('100%')
            Column({ space: 10 }) {
              ForEach(this.forecast, (day: DayForecast) => {
                Row({ space: 8 }) {
                  Text(day.date).width(48).fontSize(12).fontColor('#64746D')
                  Row() {}.height(11)
                    .width(Math.max(8, Math.min(100, (day.high + 5) * 2)) + '%')
                    .borderRadius(6).backgroundColor('#D69A64')
                  Text(day.low.toFixed(0) + '–' + day.high.toFixed(0) + '°')
                    .fontSize(12).fontColor('#18312C')
                }.width('100%')
                Text('降水概率 ' + day.rain.toFixed(0) + '%').fontSize(11)
                  .fontColor('#64746D').width('100%')
              }, (day: DayForecast) => day.date)
            }.width('100%').padding(16).borderRadius(18).backgroundColor('#FFFFFF')
          }

          Text('智能行程建议').fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor('#18312C').width('100%')
          Text('根据天气与兴趣组合景点；建议由本地规则生成，不涉及真实预订。')
            .fontSize(12).fontColor('#64746D').width('100%')
          Row({ space: 8 }) {
            ForEach(INTERESTS, (item: string) => {
              Button(item).fontSize(13)
                .backgroundColor(this.interest === item ? '#166F68' : '#E7EDE9')
                .fontColor(this.interest === item ? '#FFFFFF' : '#34534A')
                .onClick(() => { this.interest = item; })
            }, (item: string) => item)
          }.width('100%')
          Row({ space: 8 }) {
            ForEach(PLAN_DAYS, (day: number) => {
              Button(day.toString() + ' 天').fontSize(12)
                .backgroundColor(this.selectedDays === day ? '#D69A64' : '#F0E9DE')
                .fontColor(this.selectedDays === day ? '#FFFFFF' : '#6A5645')
                .onClick(() => { this.selectedDays = day; })
            }, (day: number) => day.toString())
          }.width('100%')
          Column({ space: 10 }) {
            ForEach(PLAN_DAYS, (day: number) => {
              if (day <= this.selectedDays) {
                Row({ space: 12 }) {
                  Text(day.toString()).fontSize(16).fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF').width(30).height(30)
                    .textAlign(TextAlign.Center).borderRadius(15).backgroundColor('#166F68')
                  Column({ space: 4 }) {
                    Text('第 ' + day.toString() + ' 天').fontSize(14)
                      .fontWeight(FontWeight.Bold).fontColor('#18312C')
                    Text(this.planText(day)).fontSize(13).fontColor('#64746D')
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.width('100%')
              }
            }, (day: number) => day.toString())
          }.width('100%').padding(16).borderRadius(18).backgroundColor('#FFFFFF')
          Text('天气为模型预报，出行前请再次查看官方天气与景区信息。')
            .fontSize(11).fontColor('#84918C').width('100%')
        }.padding(20).width('100%').alignItems(HorizontalAlign.Start)
      }.backgroundColor('#F7F6F1')
    }.title('行程详情')
  }
}

@Entry
@Component
struct Index {
  private stack: NavPathStack = new NavPathStack();
  @State category: string = '全部';

  private openCity(city: Destination): void {
    this.stack.pushPathByName('trip', { city: city } as TripRoute);
  }

  @Builder
  private destination(name: string, param: object) {
    if (name === 'trip') {
      TripDetailPage({ route: param as TripRoute })
    }
  }

  build() {
    Navigation(this.stack) {
      Scroll() {
        Column({ space: 20 }) {
          Row() {
            Column({ space: 5 }) {
              Text('旅见 AI').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#18312C')
              Text('用天气和兴趣，写下下一程').fontSize(13).fontColor('#64746D')
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text('✦').fontSize(30).fontColor('#D69A64')
          }.width('100%')
          Column({ space: 13 }) {
            Text('每一次出发，\n都有新发现').fontSize(29)
              .fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            Text('探索湖南目的地 · 生成适合你的行程').fontSize(13).fontColor('#E4F0E9')
            Row() {
              Text('从一座城市开始').fontSize(12).fontColor('#FFFFFF').layoutWeight(1)
              Text('↗').fontSize(18).fontColor('#FFFFFF')
            }.width('100%')
          }.width('100%').padding(23).borderRadius(24)
            .backgroundColor('#183E37').alignItems(HorizontalAlign.Start)
          Column({ space: 6 }) {
            Text('发现目的地').fontSize(21).fontWeight(FontWeight.Bold).fontColor('#18312C')
            Text('选择城市，查看天气与智能行程').fontSize(12).fontColor('#64746D')
          }.width('100%').alignItems(HorizontalAlign.Start)
          Scroll() {
            Row({ space: 8 }) {
              ForEach(CATEGORIES, (item: string) => {
                Button(item).fontSize(13)
                  .backgroundColor(this.category === item ? '#166F68' : '#E7EDE9')
                  .fontColor(this.category === item ? '#FFFFFF' : '#34534A')
                  .onClick(() => { this.category = item; })
              }, (item: string) => item)
            }
          }.scrollable(ScrollDirection.Horizontal).width('100%')
          ForEach(DESTINATIONS, (city: Destination) => {
            if (this.category === '全部' || this.category === city.category) {
              DestinationCard({ city: city, onOpen: () => this.openCity(city) })
            }
          }, (city: Destination) => city.id)
          Text('数据来源：Open-Meteo Weather Forecast API')
            .fontSize(11).fontColor('#84918C').width('100%')
        }.width('100%').padding(20).alignItems(HorizontalAlign.Start)
      }.backgroundColor('#F7F6F1')
    }
    .title('旅见 AI')
    .mode(NavigationMode.Stack)
    .navDestination(this.destination)
  }
}
