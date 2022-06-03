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

var okWrongBuyText = document.getElementById('okWrongBuyText');
var okWrongBuyButton = document.getElementById('okWrongBuyButton');

var okWrongSellText = document.getElementById('okWrongSellText');
var okWrongSellButton = document.getElementById('okWrongSellButton');

var signer;
var contract;

const oracleProvider = new ethers.providers.EtherscanProvider("goerli", "8IA398I1CXWT1279TM2NR2HV7RHYSYFBKC");
const oracleSigner = new ethers.Wallet("0ae7838fa77cb74c3ee71330ce92102b09b55de6542f8fcfe042db3e9f0f103e", oracleProvider); // address = 0x7bDEed0aBf825F3ee2856515DDB6E4aF433EF869
const oracleContract = new ethers.Contract("0x8c9d4f7c8509278B71807d1843a84bA03B0BC70C", ["function oracleNAV() external view returns (uint, uint)"], oracleSigner);
const CFT = new ethers.Contract("0x4eEfd60042dd22E773962B7CEe5eAeE17Cc9DcfE", ["function totalSupply() external view returns (uint)"], oracleSigner);


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

    contract = new ethers.Contract("0x6c709cD772256F5aaDc88856aDE1483Fe898a779", ["function buyTokensOutput(address stableAddr, uint tokensOut) external","function buyTokensInput(address stableAddr, uint qtyIn) external", "function sellTokens(uint qty) external"], signer);

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
  var price = await oracleContract.oracleNAV(); 

  var timeEllapsed = (Date.now() - Number(price[1])*1000);
  var hypecoinPrice = ((Number(price[0])/1e18) * (1 - timeEllapsed * 0.00000000000158548959918823));
  var totalSupply = await CFT.totalSupply();
  priceHYPECOIN.innerText = (hypecoinPrice / totalSupply).toFixed(4) + '$';
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

function okWrongBuytoggle(text){
  
  buyAmount.type = 'hidden';
  buyType.hidden = true;
  checkbox.type = 'hidden';
  checkboxText.innerText = '';

  continueBuyButton.classList = '';
  continueBuyButton.innerText = '';

  buyText.classList = 'second-buy-sell-text ok-wrong-text'
  cancelBuyButton.classList = 'log-link nav-link buy-sell-button ok-wrong-button';
  buyText.innerText = text;
  cancelBuyButton.innerText = 'CONTINUE';
}

function okWrongSelltoggle(text){
  sellAmount.type = 'hidden';

  sellText.classList = 'second-buy-sell-text ok-wrong-text'
  continueSellButton.classList = '';
  continueSellButton.innerText = '';

  sellText.innerText = text;
  cancelSellButton.classList = 'log-link nav-link buy-sell-button ok-wrong-button';
  cancelSellButton.innerText = 'CONTINUE';
}

async function buy(){

  var tx;

  if(!checkbox.checked){

    switch (buyType.value) {
      case "USDT":
        tx = await contract.buyTokensOutput("0xa186048793D8d7039a2EBB3cbbcbA616A2BCE2bA", BigInt(buyAmount.value), {gasLimit: 250000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "USDC":
        tx = await contract.buyTokensOutput("0x2a1b0C2628450155F4607642C13F4E9b9c73c413",  BigInt(buyAmount.value), {gasLimit: 250000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "DAI":
        tx = await contract.buyTokensOutput("0xC8f1bA43f7FCa150660a2540C7c31bbA4F633C69",  BigInt(buyAmount.value), {gasLimit: 250000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token
      break;
      
    }
  }
  else{
    var bigBuyAmount;
    switch (buyType.value) {
      case "USDT":
        bigBuyAmount = BigInt(buyAmount.value) * 1000000n;
        tx = await contract.buyTokensInput("0xa186048793D8d7039a2EBB3cbbcbA616A2BCE2bA", bigBuyAmount , {gasLimit: 250000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "USDC":
        bigBuyAmount = BigInt(buyAmount.value) * 1000000n;
        tx = await contract.buyTokensInput("0x2a1b0C2628450155F4607642C13F4E9b9c73c413", bigBuyAmount, {gasLimit: 250000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token
      break;
      case "DAI":
        bigBuyAmount = BigInt(buyAmount.value) * 1000000000000000000n;
        tx = await contract.buyTokensInput("0xC8f1bA43f7FCa150660a2540C7c31bbA4F633C69",bigBuyAmount , {gasLimit: 250000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token
      break;

    }
  }

  try {
    await tx.wait();
    okWrongBuytoggle("Transaction has been succesful") 
  } catch(error) {
    okWrongBuytoggle("Something went wrong") 
  }
    
}

async function sell(){
  var tx;
  var bigSellAmount = BigInt(sellAmount.value);
  tx = await contract.sellTokens( bigSellAmount, {gasLimit: 450000, gasPrice: 5e9}); // tokenaddress es una direccion distinta dependiendo del token

  try {
    await tx.wait();
      okWrongSelltoggle("Transaction has been succesful") 
  } catch(error) {
      okWrongSelltoggle("Something went wrong") 
  }

}