import ServiceManagement
import Testing
@testable import NotchMusic

@MainActor
struct LoginItemTests {
    private final class Service: LoginItemService {
        var status: SMAppService.Status = .notRegistered
        var registrations = 0
        var fail = false
        func register() throws {
            if fail { throw Failure.denied }
            registrations += 1
            status = .enabled
        }
        func unregister() throws { status = .notRegistered }
        enum Failure: Error { case denied }
    }

    @Test func reflectsRegistrationAndExternalChanges() {
        let service = Service()
        let controller = LoginItemController(service: service, canConfigure: true)
        controller.setEnabled(true)
        #expect(controller.isEnabled)
        controller.setEnabled(true)
        #expect(service.registrations == 1)
        service.status = .requiresApproval
        controller.refresh()
        #expect(controller.needsApproval)
        controller.setEnabled(false)
        #expect(!controller.isEnabled)
    }

    @Test func failuresAndUninstalledCopiesStayDisabled() {
        let service = Service()
        service.fail = true
        let controller = LoginItemController(service: service, canConfigure: true)
        controller.setEnabled(true)
        #expect(!controller.isEnabled)
        #expect(controller.errorMessage != nil)
        let uninstalled = LoginItemController(service: service, canConfigure: false)
        uninstalled.setEnabled(true)
        #expect(service.registrations == 0)
        #expect(uninstalled.errorMessage != nil)
    }
}
