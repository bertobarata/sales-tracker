import XCTest

/// Fumo: percorre os quatro separadores numa base de dados vazia.
/// É o cenário do primeiro arranque e o que mais facilmente rebenta,
/// porque os gráficos de Tendências recebem séries sem qualquer ponto.
@MainActor
final class TabSmokeTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// A introdução é saltada por argumento de lançamento. Sem isso, o resultado destes
    /// testes dependia de o simulador já a ter visto numa execução anterior.
    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--skip-onboarding", "--empty-store"] + extraArguments
        app.launch()
        return app
    }

    func testAllTabsRenderOnEmptyDatabase() {
        let app = launchApp()

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

    /// O que se perdia antes: escrever um número, mudar de separador e voltar a um campo
    /// vazio. Agora grava sozinho, e é isso que este teste verifica de ponta a ponta.
    func testDailyEntrySurvivesTabSwitch() {
        let app = launchApp()

        app.tabBars.buttons["Hoje"].tap()

        let increment = app.buttons.matching(identifier: "stepper.increment").firstMatch
        XCTAssertTrue(increment.waitForExistence(timeout: 10), "Botão + não apareceu")
        increment.tap()

        let field = app.textFields["Contactos efetuados"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Campo dos contactos não apareceu")
        XCTAssertEqual(field.value as? String, "1")

        // Sair do separador força a gravação sem esperar pelo atraso de 400 ms.
        app.tabBars.buttons["Semana"].tap()
        XCTAssertTrue(app.navigationBars["Semana"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Hoje"].tap()

        XCTAssertTrue(field.waitForExistence(timeout: 10), "Campo não voltou a aparecer")
        XCTAssertEqual(field.value as? String, "1", "O valor não sobreviveu à mudança de separador")
    }

    /// O campo do valor formatava a moeda a cada tecla: escrever "1" virava "1,00 €" e o
    /// resto ia por cima. E não havia como fechar o teclado do teclado numérico.
    func testWeeklyValueCanBeTypedAndKeyboardDismissed() {
        let app = launchApp()

        app.tabBars.buttons["Relatório"].tap()
        XCTAssertTrue(app.navigationBars["Relatório"].waitForExistence(timeout: 10))

        let field = app.textFields["Valor total"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Campo do valor não apareceu")
        field.tap()
        field.typeText("1450")

        let done = app.buttons["OK"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Sem botão para fechar o teclado")
        done.tap()

        let shown = (field.value as? String) ?? ""
        XCTAssertTrue(shown.contains("450"), "O valor escrito não ficou no campo: \(shown)")
        XCTAssertTrue(shown.contains("€"), "O valor não ficou formatado como moeda: \(shown)")
    }

    /// Escrever por cima de um valor já existente era o caso pior: o texto antigo ficava
    /// lá e o novo era inserido no meio — "1000" mais "2500" dava 25 001 000,00 €.
    func testExistingValueCanBeReplaced() {
        let app = launchApp()

        app.tabBars.buttons["Relatório"].tap()
        let field = app.textFields["Valor total"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))

        field.tap()
        field.typeText("1000")
        app.buttons["OK"].tap()

        field.tap()
        field.typeText("2500")
        app.buttons["OK"].tap()

        let shown = (field.value as? String) ?? ""
        XCTAssertTrue(shown.contains("500"), "Não deixou substituir o valor: \(shown)")
        XCTAssertFalse(shown.contains("1 000"), "O valor antigo ficou lá: \(shown)")
    }

    /// Entrar no campo e sair sem escrever nada não pode apagar o que lá estava.
    func testLeavingTheFieldBlankKeepsThePreviousValue() {
        let app = launchApp()

        app.tabBars.buttons["Relatório"].tap()
        let field = app.textFields["Valor total"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))

        field.tap()
        field.typeText("750")
        app.buttons["OK"].tap()

        field.tap()
        app.buttons["OK"].tap()

        let shown = (field.value as? String) ?? ""
        XCTAssertTrue(shown.contains("750"), "Sair em branco apagou o valor: \(shown)")
    }

    func testOnboardingAppearsOnFirstLaunchAndCanBeDismissed() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-onboarding", "--empty-store"]
        app.launch()

        let skip = app.buttons["Saltar introdução"]
        XCTAssertTrue(skip.waitForExistence(timeout: 15), "A introdução não apareceu no primeiro arranque")
        skip.tap()

        XCTAssertTrue(
            app.tabBars.buttons["Hoje"].waitForExistence(timeout: 10),
            "A app não ficou utilizável depois de saltar a introdução"
        )
    }
}
