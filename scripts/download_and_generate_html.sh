#!/bin/bash
curl -s https://api.coinbase.com/v2/exchange-rates?currency=CZK -o dataset.json
jq '.data.rates.USD, .data.rates.EUR' dataset.json
echo "<html><body><table>" > exchange_rates.html
echo "<tr><th>Currency</th><th>Rate</th></tr>" >> exchange_rates.html
echo "<tr><td>USD</td><td>$(jq -r '.data.rates.USD' dataset.json)</td></tr>" >> exchange_rates.html
echo "<tr><td>EUR</td><td>$(jq -r '.data.rates.EUR' dataset.json)</td></tr>" >> exchange_rates.html
echo "</table></body></html>" >> exchange_rates.html