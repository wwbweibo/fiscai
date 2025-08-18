import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private let CHANNEL = "com.example.fiscai/android"
  
  // 截图监听相关属性
  private var isScreenshotListening = false
  private var screenshotMethodChannel: FlutterMethodChannel?
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
    
    // 设置截图监听器的Method Channel
    self.screenshotMethodChannel = methodChannel
    
    // 设置通知代理
    UNUserNotificationCenter.current().delegate = self
    
    // 处理Method Channel调用
    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleMethodCall(call, result: result)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // 处理通知启动的情况
    if let notificationResponse = launchOptions?[.remoteNotification] as? [String: Any] {
      handleLaunchFromNotification(notificationResponse)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Method Channel处理
  
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "registScreenshotListener":
      let success = startScreenshotListening()
      result(success)
      
    case "unregistScreenshotListener":
      stopScreenshotListening()
      result(true)
      
    case "startBackgroundScreenshotService":
      let success = startScreenshotListening()
      result(success)
      
    case "stopBackgroundScreenshotService":
      stopScreenshotListening()
      result(true)
      
    case "isBackgroundServiceRunning":
      result(isScreenshotListening)
      
    case "requestNotificationPermission":
      requestNotificationPermission { granted in
        result(granted)
      }
      
    case "getScreenshotStorageInfo":
      // iOS无法获取截图存储信息
      result([
        "file_count": 0,
        "total_size_bytes": 0,
        "total_size_mb": 0,
        "directory_path": "iOS不支持截图文件管理"
      ])
      
    case "cleanupScreenshotFiles":
      // iOS无需清理截图文件
      result(true)
      
    case "processUriToImage":
      // iOS不需要URI处理
      result(nil)
      
    case "isUriAccessible":
      // iOS不使用URI方式
      result(false)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - 权限处理
  
  private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
  
  // MARK: - 截图监听功能
  
  private func startScreenshotListening() -> Bool {
    guard !isScreenshotListening else { return true }
    
    // 请求通知权限
    requestNotificationPermission { [weak self] granted in
      if granted {
        self?.registerScreenshotNotification()
        self?.isScreenshotListening = true
        NSLog("iOS截图监听已启动")
      } else {
        NSLog("通知权限被拒绝，无法启动截图监听")
      }
    }
    
    return true
  }
  
  private func stopScreenshotListening() {
    guard isScreenshotListening else { return }
    
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    
    isScreenshotListening = false
    NSLog("iOS截图监听已停止")
  }
  
  private func registerScreenshotNotification() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
  }
  
  @objc private func screenshotTaken() {
    NSLog("检测到iOS截图事件")
    
    // 启动后台任务
    startBackgroundTask()
    
    // 显示本地通知
    showScreenshotNotification()
    
    // 通知Flutter层
    DispatchQueue.main.async { [weak self] in
      self?.screenshotMethodChannel?.invokeMethod("onScreenshotDetected", arguments: [
        "imagePath": "" // iOS无法直接获取截图路径
      ])
    }
  }
  
  private func startBackgroundTask() {
    // 结束之前的后台任务
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
    }
    
    backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
      // 后台任务即将结束
      if let taskId = self?.backgroundTaskId, taskId != .invalid {
        UIApplication.shared.endBackgroundTask(taskId)
        self?.backgroundTaskId = .invalid
      }
    }
  }
  
  private func showScreenshotNotification() {
    let center = UNUserNotificationCenter.current()
    
    // 创建通知内容
    let content = UNMutableNotificationContent()
    content.title = "检测到截图"
    content.body = "是否需要为您识别并记录账单？"
    content.sound = .default
    content.badge = 1
    
    // 添加操作按钮
    let recognizeAction = UNNotificationAction(
      identifier: "RECOGNIZE_BILL",
      title: "识别账单",
      options: [.foreground]
    )
    
    let ignoreAction = UNNotificationAction(
      identifier: "IGNORE",
      title: "忽略",
      options: []
    )
    
    let category = UNNotificationCategory(
      identifier: "SCREENSHOT_CATEGORY",
      actions: [recognizeAction, ignoreAction],
      intentIdentifiers: [],
      options: []
    )
    
    center.setNotificationCategories([category])
    content.categoryIdentifier = "SCREENSHOT_CATEGORY"
    
    // 创建通知请求
    let request = UNNotificationRequest(
      identifier: "screenshot_notification",
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    )
    
    // 发送通知
    center.add(request) { error in
      if let error = error {
        NSLog("发送通知失败: \(error.localizedDescription)")
      } else {
        NSLog("截图通知已发送")
      }
    }
  }
  
  private func handleNotificationAction(_ action: String) {
    NSLog("处理通知操作: \(action)")
    
    DispatchQueue.main.async { [weak self] in
      self?.screenshotMethodChannel?.invokeMethod("onNotificationAction", arguments: [
        "action": action,
        "screenshot_path": nil // iOS无法提供截图路径
      ])
    }
    
    // 结束后台任务
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
      backgroundTaskId = .invalid
    }
  }
  
  // MARK: - 通知启动处理
  
  private func handleLaunchFromNotification(_ userInfo: [String: Any]) {
    // 处理从通知启动应用的情况
    NSLog("应用通过通知启动")
  }
  
  deinit {
    stopScreenshotListening()
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate {
  
  // 应用在前台时收到通知
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 在前台也显示通知
    completionHandler([.alert, .sound, .badge])
  }
  
  // 用户点击通知
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    
    let actionIdentifier = response.actionIdentifier
    
    switch actionIdentifier {
    case "RECOGNIZE_BILL":
      handleNotificationAction("recognize_bill")
    case "IGNORE":
      handleNotificationAction("ignore")
    case UNNotificationDefaultActionIdentifier:
      // 用户点击通知本身
      handleNotificationAction("open_app")
    default:
      break
    }
    
    completionHandler()
  }
}
