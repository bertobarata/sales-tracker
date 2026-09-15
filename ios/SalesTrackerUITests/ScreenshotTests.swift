import XCTest

/// Capturas para a App Store. Corre a app com `--demo-data`, que a arranca
/// com base em memória já semeada, e guarda uma imagem por separador.
/// As imagens saem no `.xcresult` como anexos e extraem-se com `xcresulttool`.
@MainActor
final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data"]
        app.launch()

        let tabs = ["Hoje", "Semana", "Relatório", "Tendências"]

        for (index, tab) in tabs.enumerated() {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 20), "Separador \(tab) não apareceu")
            button.tap()
            XCTAssertTrue(
                app.navigationBars[tab].waitForExistence(timeout: 20),
                "Ecrã \(tab) não renderizou"
            )

            // Dá tempo aos gráficos de Tendências para desenharem antes do disparo.
            Thread.sleep(forTimeInterval: 1.5)
            capture(named: String(format: "%02d-%@", index + 1, slug(tab)))
        }
    }

    private func capture(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func slug(_ value: String) -> String {
        value.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }
}
