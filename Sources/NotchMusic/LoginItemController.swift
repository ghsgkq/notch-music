import AppKit
import ServiceManagement

@MainActor
protocol LoginItemService {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

@MainActor
private struct SystemLoginItemService: LoginItemService {
    var status: SMAppService.Status { SMAppService.mainApp.status }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var status: SMAppService.Status = .notRegistered
    @Published private(set) var errorMessage: String?
    let canConfigure: Bool
    private let service: any LoginItemService

    var isEnabled: Bool { status == .enabled || status == .requiresApproval }
    var needsApproval: Bool { status == .requiresApproval }

    init(service: (any LoginItemService)? = nil, canConfigure: Bool? = nil) {
        self.service = service ?? SystemLoginItemService()
        let appURL = Bundle.main.bundleURL
        let applications = ["/Applications", NSHomeDirectory() + "/Applications"]
        self.canConfigure = canConfigure ?? (appURL.pathExtension == "app" && applications.contains(appURL.deletingLastPathComponent().path))
        refresh()
    }

    func refresh() { status = service.status }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        guard canConfigure else {
            errorMessage = "앱을 응용 프로그램 폴더로 옮긴 뒤 설정해 주세요."
            return
        }
        refresh()
        guard enabled != isEnabled else { return }
        do {
            if enabled { try service.register() } else { try service.unregister() }
        } catch {
            errorMessage = "로그인 항목을 변경하지 못했습니다: \(error.localizedDescription)"
        }
        refresh()
    }

    func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }
}
