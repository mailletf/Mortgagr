
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

world =
    year: 0
    accounts: outside: 0
    print: -> console.log @year, @accounts
    addAccount: (x) -> @accounts[x] = 0
    transfer: (from, to, amount, flag = true) ->
        @accounts[from] -= npv(amount, @year)
        @accounts[to]   += if flag then npv(amount, @year) else amount
    appreciate: (act, pct) ->
        @accounts[act] *= 1+pct
    setScenario: ({init, scenario}) ->
        @init = init
        @scenario = scenario
    stepOneYear: ->
        @scenario()
        @print()
        @year++


sellIn10 =
    init: ->
        @addAccount "condo"
        @addAccount "cash"
        @addAccount "principal"
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
            #@transfer "condo", "buyer", @accounts.condo
            @transfer "cash", "principal", 0-@accounts.principal, false

        @appreciate "cash", 0.03

rentFor10 =
    init: ->
        @addAccount "cash"
        @addAccount "landlord"
    scenario: ->
        if @year == 0
            @transfer "outside", "cash", 60000
        @transfer "outside", "cash", 15000
        @transfer "cash", "landlord", 12*1200
        @appreciate "cash", 0.03

world.setScenario(rentFor10)

world.init()
accounts = (k for k of world.accounts)
tableHTML = "<table border=1 cellpadding=5>"
tableHTML += "<tr><th>yr</th><th>#{accounts.join("</th><th>")}</th></tr>"
for y in [0..10]
    world.stepOneYear()
    row = (world.accounts[k].toFixed(2) for k in accounts)
    row.unshift world.year-1
    tableHTML += "<tr><td>#{row.join("</td><td>")}</td></tr>"

tableHTML += "</table>"

s = require("http").createServer (req,res) -> res.end tableHTML
s.listen 8080
