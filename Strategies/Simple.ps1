﻿$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 1000
    [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "-15"
    $aggressivenessPct = "10"

    # Market is reversing after a downtrend??
    if ($pctChange24h -gt -10)
    {
        if ($pctChangeFromATH -le -35 -and $bagPct -lt 60) {
            $bemPct = "2"
        }
        elseif ($pctChangeFromATH -le -20) {
            $bemPct = "0"
        } 
        elseif ($pctChangeFromATH -le -10) {
            $bemPct = "-5"
        }
    }

    #Write-Host "[$Marketname] $pctChangeFromAth, $bemPct, $aggressivenessPct"
    Set-GSMGSetting -Market $marketName -BemPct $bemPct -AggressivenessPct $aggressivenessPct
}
