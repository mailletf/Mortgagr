
inflation = 0.03

condoPrice = 310000
downPayment = 60000

payment = 14500
interest = 0.0345


npv = (amount, year) ->
    for y in [0...year]
        amount /= 1+inflation
    return amount

pctCapital = (payment, interest, amount, year) ->
    for y in [0...year]
        periodInterest = amount*interest
        amount -= payment-periodInterest
    return (payment-periodInterest)/payment

class World
    constructor: ({init, scenario}) ->
        @init = init
        @scenario = scenario
        @year = 0
        @accounts = outside: 0
        @netWorthAccounts = []
    
    netWorth: -> 
        result = 0
        result += @accounts[x] for x in @netWorthAccounts
        return result
    
    print: -> console.log @year, @accounts
    
    addAccount: (act, netWorth = false) -> 
        @accounts[act] = 0
        @netWorthAccounts.push act if netWorth
    
    transfer: (from, to, amount, flag = true) ->
        @accounts[from] -= npv(amount, @year)
        @accounts[to]   += if flag then npv(amount, @year) else amount
    
    appreciate: (act, pct) ->
        @accounts[act] *= 1+pct
    
    stepOneYear: ->
        @scenario()
        #@print()
        @year++

scenarios = 
    sellIn10:
        init: ->
            @addAccount "condo"
            @addAccount "cash", true
            @addAccount "principal", true
            @addAccount "interest"
            @addAccount "buyer"
        scenario: ->
            if @year == 0
                @transfer "outside", "condo", 60000
                @transfer "principal", "condo", 250000

            if @year > 0
                @transfer "outside", "cash", 15000
                interestPayment = 0 - (interest * @accounts.principal)
                principalPayment = payment - interestPayment
                @transfer "cash", "principal", principalPayment, false
                @transfer "cash", "interest", interestPayment

            if @year == 10
                @transfer "buyer", "cash", 280000
                @transfer "cash", "principal", 0-@accounts.principal, false

            @appreciate "cash", 0.03

    rentFor10:
        init: ->
            @addAccount "cash", true
            @addAccount "landlord"
        scenario: ->
            if @year == 0
                @transfer "outside", "cash", 60000
            @transfer "outside", "cash", 15000
            @transfer "cash", "landlord", 12*1200
            @appreciate "cash", 0.03

s = require("http").createServer (req, res) ->
    scenarioName = req.url.replace("/","")
    if not scenarios[scenarioName]?
        return res.end "no such scenario"

    world = new World(scenarios[scenarioName])
    world.init()
    accounts = (k for k of world.accounts)
    tableHTML = "<table border=1 cellpadding=5>"
    tableHTML += "<tr><th>Year</th>"
    tableHTML += "<th>#{accounts.join("</th><th>")}</th>"
    tableHTML += "<th>Net Worth</th></tr>"
    for y in [0..10]
        world.stepOneYear()
        row = (world.accounts[k].toFixed(2) for k in accounts)
        row.unshift world.year-1
        row.push world.netWorth().toFixed(2)
        tableHTML += "<tr><td>#{row.join("</td><td>")}</td></tr>"
    tableHTML += "</table>"

    res.end tableHTML

s.listen 8080
