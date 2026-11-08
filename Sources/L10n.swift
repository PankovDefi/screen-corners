import Foundation

/// Tiny RU/EN localization based on the system language.
enum L10n {
    static let isRussian: Bool = (Locale.preferredLanguages.first ?? "en").hasPrefix("ru")

    private static func t(_ en: String, _ ru: String) -> String { isRussian ? ru : en }

    static var enabled: String      { t("Round corners", "Скруглять углы") }
    static func radius(_ v: Double) -> String {
        t("Radius: \(Int(v)) pt", "Радиус: \(Int(v)) pt")
    }
    static func resetRadius(_ v: Double) -> String {
        t("Reset radius (\(Int(v)) pt)", "Сбросить радиус (\(Int(v)) pt)")
    }
    static var topCorners: String   { t("Top corners too", "Верхние углы тоже") }
    static var allDisplays: String  { t("External displays too", "Внешние мониторы тоже") }
    static var launchAtLogin: String { t("Launch at login", "Запускать при входе") }
    static var hideIcon: String     { t("Hide menu bar icon…", "Скрыть иконку…") }
    static var github: String       { t("Open on GitHub", "Открыть на GitHub") }
    static var quit: String         { t("Quit Screen Corners", "Выйти из Screen Corners") }

    static var hideIconTitle: String { t("Hide the menu bar icon?", "Скрыть иконку из строки меню?") }
    static var hideIconText: String {
        t("Corners will keep working. To bring the icon back, open Screen Corners again from Applications or Spotlight.",
          "Углы продолжат работать. Чтобы вернуть иконку, снова откройте Screen Corners из «Программ» или через Spotlight.")
    }
    static var hide: String   { t("Hide", "Скрыть") }
    static var cancel: String { t("Cancel", "Отмена") }

    static var loginErrorTitle: String { t("Couldn't enable launch at login", "Не удалось включить автозапуск") }
}
