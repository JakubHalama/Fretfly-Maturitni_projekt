#!/bin/bash
echo "🔍 Kontroluji připojená zařízení..."
flutter devices

echo ""
echo "📱 Pokud vidíš svůj iPhone v seznamu, spusť:"
echo "   flutter run -d <ID_tvého_iPhonu>"
echo ""
echo "💡 Nebo jednoduše:"
echo "   flutter run"
echo ""
echo "⚠️  Pokud iPhone nevidíš:"
echo "   1. Připoj iPhone kabelem k Macu"
echo "   2. Na iPhonu: Nastavení → Obecné → VPN a správa zařízení"
echo "   3. Důvěřuj vývojáři (tvoje Apple ID)"
echo "   4. Zkontroluj v Xcode: Window → Devices and Simulators"
