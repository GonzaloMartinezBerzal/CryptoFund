const ethers = require('ethers')
const fetch = require("node-fetch");
const fs = require("fs");

const provider = new ethers.providers.EtherscanProvider('homestead', 'MNETCZYURMCR4EFHU72CZGTDQPCDRMFIS3');
let signer = new ethers.Wallet('bcabd80caaf5a114ae0d56a6a71a570908850c770f1a4183380041322d59a3b4', provider)

const contract = new ethers.Contract('0x731caeCD3d64443e7aB4967282f3201599c0A170',['function uniSwap(address[] calldata path, uint amount) external'], signer)

async function getPrices()
{
	const request = async (url) =>
	{
		const response = await fetch(url);
		if (!response.ok) throw new Error("WARN", response.status);
		const data = await response.json();
		return data;
	}
	
	let MATICprice = await request('https://min-api.cryptocompare.com/data/pricemulti?fsyms=MATIC&tsyms=USD')
	return MATICprice.MATIC.USD;
}

async function swap()
{
	let MATICprice = await getPrices();
	const file = fs.readFileSync('lastPrice.log', 'utf8');
  	if (Number(file) != 0)
  	{
  		if(price < file)
		{
			console.log('compra')
			let tx = await contract.uniSwap(['0xC8f1bA43f7FCa150660a2540C7c31bbA4F633C69','0x3A011180F15b09EEcBAea1e0D260F4690F6A0a08'], {gasPrice: 2.5e9, gasLimit: 250000});
			console.error(`Transaction info at https://etherscan.io/tx/${tx.hash}`)
			console.error('Transaction in progress...\n')
			try
			{
				const receipt = await tx.wait();
			} catch(error)
			{
				console.error(error);
			}
		}

		else if(price > file)
		{
			console.log('vende')
			let tx = await contract.uniSwap(['0x3A011180F15b09EEcBAea1e0D260F4690F6A0a08', '0xC8f1bA43f7FCa150660a2540C7c31bbA4F633C69'], {gasPrice: 2.5e9, gasLimit: 250000});
			console.error(`Transaction info at https://etherscan.io/tx/${tx.hash}`)
			console.error('Transaction in progress...\n')
			try
			{
				const receipt = await tx.wait();
			} catch(error)
			{
				console.error(error);
			}
		}
  	}
	
	fs.writeFileSync('lastPrice.log', MATICprice.toString());
}

swap();