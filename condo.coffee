# make calculations match ing
# add municipal taxes
# rent3sell7
# 


inflation = 0.03
investmentInterest = 0.03

condoPrice = 310000
downPayment = 60000

salePrice = 280000

rentalPrice = 1200 #monthly
yearlyInput = 17000

taxes = 2000

payment = 14500
interest = 0.0345


npv = (amount, year) ->
    for y in [0...year]
        amount /= 1+inflation
    return amount

class World
    constructor: ({init, scenario}) ->
        @init = init
        @scenario = scenario
        @year = 0
        @accounts = outside: 0
    
    addAccount: (act) ->
        @accounts[act] = 0
    
    transfer: (from, to, amount, flag = true) ->
        @accounts[from] -= npv(amount, @year)
        @accounts[to]   += if flag then npv(amount, @year) else amount
    
    appreciate: (act, pct) ->
        @accounts[act] *= 1+pct
    
    stepOneYear: ->
        @scenario()
        @year++

scenarios =
    sellIn10:
        init: ->
            @addAccount "seller"
            @addAccount "cash"
            @addAccount "principal"
            @addAccount "interest"
            @addAccount "buyer"
            @addAccount "govt"
        scenario: ->
            if @year == 0
                @transfer "outside", "seller", downPayment
                @transfer "principal", "seller", condoPrice-downPayment

        
            @transfer "outside", "cash", yearlyInput
            interestPayment = 0 - (interest * @accounts.principal)
            principalPayment = payment - interestPayment
            @transfer "cash", "principal", principalPayment, false
            @transfer "cash", "interest", interestPayment
            @transfer "cash", "govt", taxes

            if @year == 10
                @transfer "buyer", "cash", salePrice
                @transfer "cash", "principal", 0-@accounts.principal, false

            @appreciate "cash", investmentInterest

    rentFor10:
        init: ->
            @addAccount "cash"
            @addAccount "landlord"
        scenario: ->
            if @year == 0
                @transfer "outside", "cash", downPayment
            @transfer "outside", "cash", yearlyInput
            @transfer "cash", "landlord", 12*rentalPrice*1.02^(@year+1)
            @appreciate "cash", investmentInterest

addCommas = (nStr) ->
    nStr += ''
    x = nStr.split('.')
    x1 = x[0]
    x2 = if x.length > 1 then  '.' + x[1] else ''
    rgx = /(\d+)(\d{3})/
    x1 = x1.replace(rgx, '$1' + ',' + '$2') while rgx.test(x1)
    return x1 + x2

s = require("http").createServer (req, res) ->
    scenarioName = req.url.replace("/","")
    if not scenarios[scenarioName]?
        return res.end "no such scenario"

    world = new World(scenarios[scenarioName])
    world.init()
    accounts = (k for k of world.accounts)
    tableHTML = "<style>td {text-align: right;}</style>"
    tableHTML += "<table border=1 cellpadding=8>"
    tableHTML += "<tr><th>Year</th>"
    tableHTML += "<th>#{accounts.join("</th><th>")}</th>"
    for y in [0..10]
        world.stepOneYear()
        row = (addCommas world.accounts[k].toFixed(2) for k in accounts)
        row.unshift world.year-1
        tableHTML += "<tr><td>#{row.join("</td><td>")}</td></tr>"
    tableHTML += "</table>"

    res.end tableHTML

s.listen 8080
