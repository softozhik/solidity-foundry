import './style.css'
import { BrowserProvider, Contract, formatUnits } from 'ethers'

const TOKEN_ADDRESS = '0x209D6d1050D5F400dC020fCeed1E72741015da66'
const SEPOLIA_CHAIN_ID = 11155111n

// Для чтения баланса достаточно этих двух функций контракта.
const TOKEN_ABI = [
  'function balanceOf(address account) view returns (uint256)',
  'function decimals() view returns (uint8)',
]

document.querySelector('#app').innerHTML = `
  <h1>Study Token</h1>
  <button id="connect">Подключить MetaMask</button>
  <p id="status">Кошелёк не подключён</p>
  <p>Аккаунт: <span id="account">—</span></p>
  <p>Баланс: <span id="balance">—</span></p>
`

const connectButton = document.querySelector('#connect')
const status = document.querySelector('#status')
const accountLabel = document.querySelector('#account')
const balanceLabel = document.querySelector('#balance')

async function connectWallet() {
  if (!window.ethereum) {
    status.textContent = 'MetaMask не найден. Открой страницу в браузере с MetaMask.'
    return
  }

  connectButton.disabled = true
  accountLabel.textContent = '—'
  balanceLabel.textContent = '—'

  try {
    status.textContent = 'Подтверди подключение в MetaMask…'

    const provider = new BrowserProvider(window.ethereum)

    // Запрашиваем разрешение видеть выбранные аккаунты.
    await provider.send('eth_requestAccounts', [])

    const network = await provider.getNetwork()

    if (network.chainId !== SEPOLIA_CHAIN_ID) {
      status.textContent = 'Выбери Sepolia в MetaMask и подключись повторно.'
      return
    }

    const signer = await provider.getSigner()
    const address = await signer.getAddress()

    accountLabel.textContent = address
    status.textContent = 'Sepolia подключена. Читаем баланс…'

    // Используем provider, а не signer: только читаем данные.
    const token = new Contract(TOKEN_ADDRESS, TOKEN_ABI, provider)

    const [balance, decimals] = await Promise.all([
      token.balanceOf(address),
      token.decimals(),
    ])

    balanceLabel.textContent = `${formatUnits(balance, decimals)} STUDY`
    status.textContent = 'Баланс загружен'
  } catch (error) {
    console.error(error)
    status.textContent = `Ошибка: ${error.shortMessage ?? error.message}`
  } finally {
    connectButton.disabled = false
  }
}

connectButton.addEventListener('click', connectWallet)

// При смене аккаунта или сети сбрасываем старые данные.
if (window.ethereum) {
  window.ethereum.on('accountsChanged', () => window.location.reload())
  window.ethereum.on('chainChanged', () => window.location.reload())
}