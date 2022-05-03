var priceBNB = document.getElementById("#BNB");
var priceBTC = document.getElementById("#BTC");
var priceUNI = document.getElementById("#UNI");
var priceLINK = document.getElementById("#LINK");
var priceETH = document.getElementById("#ETH");
var priceMATIC = document.getElementById("#MATIC");
var priceHYPECOIN = document.getElementById("#HYPECOIN")

var loginButton = document.getElementById('loginButton');
var userWallet = document.getElementById('account');

//Toggle between the buy and sell   s
var buyText = document.getElementById('buyText');
var sellText = document.getElementById('sellText');

var buyButton = document.getElementById('buyButton');
var sellButton = document.getElementById('sellButton');

var continueBuyButton = document.getElementById('continueBuyButton');
var continueSellButton = document.getElementById('continueSellButton');
var cancelBuyButton = document.getElementById('cancelBuyButton');
var cancelSellButton = document.getElementById('cancelSellButton');

var sellAmount = document.getElementById('sellAmount');
var buyAmount = document.getElementById('buyAmount');
var buyType = document.getElementById('buyType');
var checkbox = document.getElementById('checkbox');
var checkboxText = document.getElementById('checkbox-text');

var signer;
var contractAdress;
var contract;

//const oracleProvider = new ethers.providers.EtherscanProvider();
//const oracleSigner = new ethers.Wallet("26440592acf000d58c919893729cfabd49a4cf41c359fac89b23203bcdd8b37a", oracleProvider); // address = 0x7bDEed0aBf825F3ee2856515DDB6E4aF433EF869
//const oracleContract = new ethers.Contract(contractAdress, ["function oracleNAV() external view returns (uint, uint)"], oracleSigner);

var web3;

document.addEventListener('DOMContentLoaded',()=>{
    getPrices();
    toggleButton();
    getHypecoinPrice();
})


function toggleButton() {
    if (!window.ethereum) {
      loginButton.innerText = 'MetaMask is not installed';
      loginButton.classList.remove('login-button');
      loginButton.classList.add('not-login-button');
      return false
    }

    loginButton.addEventListener('click', loginWithMetaMask);
}
 
async function loginWithMetaMask(){
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    const account = await signer.getAddress();

    //contract = new ethers.Contract(contractAdress, ["function buyTokensOutput(address stableAddr, uint tokensOut) external","function buyTokensInput(address stableAddr, uint qtyIn) external", "function sellTokens(uint qty) external"], signer);

    if (!account) { return; }

    window.userWalletAddress = account;
    userWallet.innerText = window.userWalletAddress;
    userWallet.classList.add('user-wallet');
    loginButton.innerText = '';
    loginButton.innerText = 'Sign out of MetaMask';

    loginButton.removeEventListener('click', loginWithMetaMask)
    setTimeout(() => {
        loginButton.addEventListener('click', signOutOfMetaMask);
    }, 200)
    
}

function signOutOfMetaMask() {
    window.userWalletAddress = null;
    userWallet.innerText = '';
    userWallet.classList.remove('user-wallet');
    loginButton.innerText = 'Sign in with MetaMask';

    loginButton.removeEventListener('click', signOutOfMetaMask);
    setTimeout(() => {
      loginButton.addEventListener('click', loginWithMetaMask);
    }, 200);
}

function getPrices(){
    const url = 'https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH,UNI,BNB,LINK,MATIC&tsyms=USD';
    fetch(url)
        .then(respuesta => respuesta.json())
        .then(respuestaJSON => {
            priceBNB.innerHTML = respuestaJSON.BNB.USD + '$';
            priceBTC.innerHTML = respuestaJSON.BTC.USD  + '$';
            priceETH.innerHTML = respuestaJSON.ETH.USD + '$';
            priceLINK.innerHTML = respuestaJSON.LINK.USD + '$';
            priceUNI.innerHTML = respuestaJSON.UNI.USD + '$';
            priceMATIC.innerHTML = respuestaJSON.MATIC.USD + '$';
        })
  }

async function getHypecoinPrice(){
  //var price = await contract.oracleNAV(); 
  //var daily = ((1 + 0.05)**(1/365));
  //var timeEllapsed = (Date.now() - price[1])/1000/3600/24;
  //var hypecoinPrice = price[0] * (1 - daily)**timeEllapsed;
  priceHYPECOIN.innerText = 0 + '$';
}

function toggleBuyView(){

  buyText.classList = 'second-buy-sell-text';
  buyText.innerText = 'Enter the amount of tokens or the money that you want to spend and the coin';
  buyButton.innerText = '';
  buyButton.classList = '';

  buyAmount.type = 'number';
  buyType.hidden = false;
  checkbox.type = 'checkbox';
  checkboxText.innerText = 'Amount of money';

  continueBuyButton.classList = 'log-link nav-link buy-sell-button continue-button';
  cancelBuyButton.classList = 'log-link nav-link buy-sell-button cancel-button';

  continueBuyButton.innerText = 'CONTINUE';
  cancelBuyButton.innerText = 'CANCEL'; 
}

function toggleSellView(){

  sellText.classList = 'second-buy-sell-text';
  sellText.innerText = 'Enter the amount of tokens that you want to sell';
  sellButton.innerText = '';
  sellButton.classList = '';

  sellAmount.type = 'number';

  continueSellButton.classList = 'log-link nav-link buy-sell-button continue-button';
  cancelSellButton.classList = 'log-link nav-link buy-sell-button cancel-button';

  continueSellButton.innerText = 'CONTINUE';
  cancelSellButton.innerText = 'CANCEL'; 
}

function untoggleBuyView(){
  
  buyText.classList = 'buy-sell-text';
  buyText.innerText = '';
  buyButton.innerText = 'BUY';
  buyButton.classList = 'log-link nav-link buy-sell-button';

  buyAmount.type = 'hidden';
  buyType.hidden = true;
  checkbox.type = 'hidden';
  checkboxText.innerText = '';

  continueBuyButton.classList = '';
  cancelBuyButton.classList = '';
  continueBuyButton.innerText = '';
  cancelBuyButton.innerText = ''; 
}

function untoggleSellView(){
  
  sellText.classList = 'buy-sell-text';
  sellText.innerText = '';
  sellButton.innerText = 'SELL';
  sellButton.classList = 'log-link nav-link buy-sell-button';

  sellAmount.type = 'hidden';

  continueSellButton.classList = '';
  cancelSellButton.classList = '';
  continueSellButton.innerText = '';
  cancelSellButton.innerText = ''; 
}

async function buy(){
  var tx;
  var tokenaddress = 0x0000000000000000000000000000000000000000;
  //comprobar checkbox
  if(checkbox.checked){

    switch (buyType) {
      case "USDT":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "USDC":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "DAI":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "UST":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
    }
  }
  else{

    switch (buyType) {
      case "USDT":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "USDC":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "DAI":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "UST":
        tx = await contract.buyTokensOutput(tokenaddress, buyAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token
      break;
    }
  }
  console.log(tx);

  try {
    await tx.wait();
    console.log("Bien"); 
  } catch(error) {
    console.log("Mal");
  }
    
}

async function sell(){
  var tx;
  var tokenaddress = 0x0000000000000000000000000000000000000000;

  await contract.sellTokens(tokenaddress, sellAmount.innerText); // tokenaddress es una direccion distinta dependiendo del token

  console.log(tx);

  try {
    await tx.wait();
    console.log("Bien"); 
  } catch(error) {
    console.log("Mal");
  }

}