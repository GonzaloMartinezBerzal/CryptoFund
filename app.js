var priceBNB = document.getElementById("#BNB");
var priceBTC = document.getElementById("#BTC");
var priceUNI = document.getElementById("#UNI");
var priceLINK = document.getElementById("#LINK");
var priceETH = document.getElementById("#ETH");
var priceMATIC = document.getElementById("#MATIC");




document.addEventListener('DOMContentLoaded',()=>{
    consultarCriptos();
})

function consultarCriptos(){
    const url = 'https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH,UNI,BNB,LINK,MATIC&tsyms=USD';
    fetch(url)
        .then(respuesta => respuesta.json())
        .then(respuestaJSON => {
            console.log(respuestaJSON);
            priceBNB.innerHTML = respuestaJSON.BNB.USD + '$';
            priceBTC.innerHTML = respuestaJSON.BTC.USD  + '$';
            priceETH.innerHTML = respuestaJSON.ETH.USD + '$';
            priceLINK.innerHTML = respuestaJSON.LINK.USD + '$';
            priceUNI.innerHTML = respuestaJSON.UNI.USD + '$';
            priceMATIC.innerHTML = respuestaJSON.MATIC.USD + '$';
        })

    
}