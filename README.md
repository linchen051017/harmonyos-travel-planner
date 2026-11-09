# 旅见 AI · 湖南旅行行程助手

移动应用开发课程项目，采用 HarmonyOS ArkTS 与 ArkUI。参考用户选定的“AI+旅游”视觉方向，界面和代码重新设计；没有复制第三方完整 UI Kit 或成品项目。

## 功能

- 首页展示长沙、张家界和凤凰古城三个目的地，可按城市、山水、古镇筛选。
- 点击目的地后通过 Navigation 进入详情页；详情页请求 Open-Meteo 未来三日天气，展示当前气温、天气描述、每日温度与降水概率。
- 根据天气与兴趣（自然、人文、美食）生成 1—3 天的行程建议。此处是可解释的本地规则推荐，并非接入大语言模型，也不提供真实预订或付款。
- 加载中、网络失败、空数据分别有提示；可在详情页重试或刷新。

## 在 DevEco Studio 中预览

1. 打开本仓库目录，等待项目同步；工程配置适配 DevEco Studio 26 与 API 23。
2. 打开 `entry/src/main/ets/pages/Index.ets`，启动手机 Previewer。
3. 点击城市卡片，观察网络加载、图表与行程建议；切换兴趣和天数，再返回首页。

工程声明了 `ohos.permission.INTERNET`。天气请求使用公开接口：

`GET https://api.open-meteo.com/v1/forecast?latitude=28.2282&longitude=112.9388&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=3&timezone=Asia%2FShanghai`

其他目的地通过各自经纬度构造同一接口。天气是模型预报，景点组合是教学演示建议；出行前应以官方天气、景区开放信息为准。

## 课程技术点

| 要求 | 实现 |
| --- | --- |
| 容器 | Row、Column、Scroll、ForEach |
| 自定义组件 | `DestinationCard` |
| 状态管理 | `@State` 管理筛选、加载、错误、天气、兴趣和天数 |
| Navigation | `NavPathStack.pushPathByName` 传递目的地、返回栈 |
| 网络 | `@kit.NetworkKit` HTTP GET，检查状态码与字段 |
| 可视化 | 由接口每日最高温生成温度条 |

## 提交前

请完成班级选题登记，核对是否重题；在本人 Previewer 中验证刷新、网络失败和空数据状态并保存真实截图；发布本人公开 Git 仓库，保存提交记录截图。姓名邓从权、学号 202440070214 的课程报告另行提供。
