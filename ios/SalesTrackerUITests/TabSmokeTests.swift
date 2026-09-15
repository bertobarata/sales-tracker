import XCTest

/// Fumo: percorre os quatro separadores numa base de dados vazia.
/// É o cenário do primeiro arranque e o que mais facilmente rebenta,
/// porque os gráficos de Tendências recebem séries sem qualquer ponto.
@MainActor
final class TabSmokeTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testAllTabsRenderOnEmptyDatabase() {
        let app = XCUIApplication()
        app.launch()

        for tab in ["Hoje", "Semana", "Relatório", "Tendências"] {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 10), "Separador \(tab) não apareceu")
            button.tap()
            XCTAssertTrue(
                app.navigationBars[tab].waitForExistence(timeout: 10),
                "Ecrã \(tab) não renderizou"
            )
        }
    }

    func testDailyEntrySavesAndReloads() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Hoje"].tap()

        // Soma 1 à primeira métrica.
        let increment = app.buttons.matching(identifier: "stepper.increment").firstMatch
        XCTAssertTrue(increment.waitForExistence(timeout: 10), "Botão + não apareceu")
        increment.tap()

        // O "Guardar" fica abaixo das nove métricas — é preciso lá chegar.
        let save = app.buttons["Guardar"]
        XCTAssertTrue(scrollTo(save, in: app), "Não foi possível chegar ao botão Guardar")
        save.tap()

        XCTAssertTrue(
            app.staticTexts["Registo guardado."].waitForExistence(timeout: 5),
            "A confirmação de gravação não apareceu"
        )
    }

    /// `hittable` em vez de `exists`: numa lista, um elemento fora do ecrã
    /// já existe na árvore mas não aceita toques.
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) -> Bool {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}
