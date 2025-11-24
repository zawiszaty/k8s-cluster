#!/bin/bash

echo "🗑️  Usuwanie klastra Kubernetes..."
echo ""

# Kolory
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funkcja sprawdzająca czy klaster istnieje
cluster_exists() {
    kind get clusters 2>/dev/null | grep -q "^platform$"
}

# Sprawdź czy klaster istnieje
if ! cluster_exists; then
    echo -e "${YELLOW}⚠️  Klaster 'platform' nie istnieje${NC}"
    echo ""
    echo "Dostępne klastry:"
    kind get clusters 2>/dev/null || echo "  (brak)"
    exit 0
fi

# Potwierdzenie
echo -e "${YELLOW}⚠️  To usunie klaster 'platform' wraz z wszystkimi zasobami!${NC}"
read -p "Czy na pewno chcesz kontynuować? (t/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Tt]$ ]]; then
    echo "❌ Anulowano"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Zatrzymywanie procesów port-forward"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
pkill -f "kubectl.*port-forward" 2>/dev/null && echo -e "${GREEN}✅ Port-forward zatrzymany${NC}" || echo "ℹ️  Brak działających port-forward"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Usuwanie klastra KIND"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kind delete cluster --name platform
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Weryfikacja"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if cluster_exists; then
    echo -e "${RED}❌ Klaster nadal istnieje - coś poszło nie tak${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Klaster został całkowicie usunięty${NC}"
fi

# Sprawdź czy pozostały kontenery Docker
REMAINING_CONTAINERS=$(docker ps -a --filter "name=platform" --format "{{.Names}}" 2>/dev/null)
if [ -n "$REMAINING_CONTAINERS" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Wykryto pozostałe kontenery:${NC}"
    echo "$REMAINING_CONTAINERS"
    read -p "Czy chcesz je również usunąć? (t/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Tt]$ ]]; then
        docker ps -a --filter "name=platform" --format "{{.ID}}" | xargs -r docker rm -f
        echo -e "${GREEN}✅ Kontenery usunięte${NC}"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Gotowe!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Klaster został usunięty. Możesz utworzyć nowy:${NC}"
echo "  ./scripts/create-cluster.sh"
echo ""
