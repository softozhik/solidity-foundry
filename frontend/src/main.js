import './style.css'
import {
  BrowserProvider,
  Contract,
  formatUnits,
  parseUnits,
  isAddress,
  ZeroAddress,
} from 'ethers'

const TOKEN_ADDRESS = '0x209D6d1050D5F400dC020fCeed1E72741015da66'
const SEPOLIA_CHAIN_ID = 11155111n

// ABI для чтения баланса и перевода токенов.
const TOKEN_ABI = [
  'function balanceOf(address account) view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function transfer(address to, uint256 amount) returns (bool)',
]

document.querySelector('#app').innerHTML = `
  <h1>Study Token</h1>
  <button id="connect">Подключить MetaMask</button>
  <p id="status">Кошелёк не подключён</p>
  <p>Аккаунт: <span id="account">—</span></p>
  <p>Баланс: <span id="balance">—</span></p>

  <form id="transfer-form">
    <fieldset id="transfer-fields" disabled>
      <legend>Перевод STUDY</legend>

      <p>
        <label>
          Адрес получателя
          <input id="recipient" type="text" required />
        </label>
      </p>

      <p>
        <label>
          Сумма STUDY
          <input
            id="amount"
            type="text"
            inputmode="decimal"
            placeholder="Например, 1.5"
            required
          />
        </label>
      </p>

      <button type="submit">Перевести</button>
    </fieldset>
  </form>
`

const connectButton = document.querySelector('#connect')
const status = document.querySelector('#status')
const accountLabel = document.querySelector('#account')
const balanceLabel = document.querySelector('#balance')
const transferForm = document.querySelector('#transfer-form')
const transferFields = document.querySelector('#transfer-fields')
const recipientInput = document.querySelector('#recipient')
const amountInput = document.querySelector('#amount')

let wallet = null
let sending = false

function errorMessage(error) {
  if (error.code === 'ACTION_REJECTED' || error.code === 4001) {
    return 'Действие отменено в MetaMask.'
  }

  return error.shortMessage ?? error.message ?? 'Неизвестная ошибка'
}

async function refreshBalance() {
  const balance = await wallet.token.balanceOf(wallet.address)
  balanceLabel.textContent =
    `${formatUnits(balance, wallet.decimals)} STUDY`
}

async function connectWallet() {
  if (!window.ethereum) {
    status.textContent = 'MetaMask не найден.'
    return
  }

  connectButton.disabled = true
  transferFields.disabled = true
  wallet = null
  accountLabel.textContent = '—'
  balanceLabel.textContent = '—'

  try {
    status.textContent = 'Подтверди подключение в MetaMask…'

    const provider = new BrowserProvider(window.ethereum)
    await provider.send('eth_requestAccounts', [])

    const network = await provider.getNetwork()

    if (network.chainId !== SEPOLIA_CHAIN_ID) {
      throw new Error('Выбери Sepolia в MetaMask и подключись повторно.')
    }

    const signer = await provider.getSigner()
    const address = await signer.getAddress()
    const token = new Contract(TOKEN_ADDRESS, TOKEN_ABI, provider)
    const decimals = await token.decimals()

    wallet = { provider, signer, address, token, decimals }

    accountLabel.textContent = address
    status.textContent = 'Sepolia подключена. Читаем баланс…'

    await refreshBalance()

    transferFields.disabled = false
    status.textContent = 'Баланс загружен. Можно переводить STUDY.'
  } catch (error) {
    console.error(error)
    wallet = null
    status.textContent = errorMessage(error)
  } finally {
    connectButton.disabled = false
  }
}

async function transferTokens(event) {
  event.preventDefault()

  if (sending || !wallet) return

  sending = true
  transferFields.disabled = true
  connectButton.disabled = true

  try {
    // Читаем текущую сеть непосредственно у кошелька.
    const chainId = await wallet.provider.send('eth_chainId', [])

    if (BigInt(chainId) !== SEPOLIA_CHAIN_ID) {
      throw new Error('Для перевода выбери Sepolia в MetaMask.')
    }

    const recipient = recipientInput.value.trim()
    const amountString = amountInput.value.trim()

    if (!isAddress(recipient)) {
      throw new Error('Некорректный адрес получателя.')
    }

    if (recipient.toLowerCase() === ZeroAddress.toLowerCase()) {
      throw new Error('Нельзя отправлять токены на нулевой адрес.')
    }

    // Разрешаем обычную десятичную запись с точкой.
    if (!/^\d+(\.\d+)?$/.test(amountString)) {
      throw new Error('Введи сумму числом с точкой, например 1.5.')
    }

    let amount

    try {
      amount = parseUnits(amountString, wallet.decimals)
    } catch {
      throw new Error(
        `Некорректная сумма: максимум ${wallet.decimals} знаков после точки.`,
      )
    }

    if (amount <= 0n) {
      throw new Error('Сумма должна быть больше нуля.')
    }

    const balance = await wallet.token.balanceOf(wallet.address)

    if (amount > balance) {
      throw new Error('Недостаточно STUDY для перевода.')
    }

    // signer позволяет запросить подпись транзакции в MetaMask.
    const writableToken = new Contract(
      TOKEN_ADDRESS,
      TOKEN_ABI,
      wallet.signer,
    )

    status.textContent = 'Проверь получателя и сумму в MetaMask…'

    const tx = await writableToken.transfer(recipient, amount)

    status.textContent =
      `Транзакция отправлена: ${tx.hash}. Ждём подтверждения…`

    await tx.wait()

    amountInput.value = ''

    // Ошибка чтения баланса не означает, что перевод не состоялся.
    try {
      await refreshBalance()
      status.textContent = `Перевод подтверждён: ${tx.hash}`
    } catch (error) {
      console.error(error)
      status.textContent =
        `Перевод подтверждён: ${tx.hash}, но обновить баланс не удалось.`
    }
  } catch (error) {
    console.error(error)
    status.textContent = errorMessage(error)
  } finally {
    sending = false
    transferFields.disabled = !wallet
    connectButton.disabled = false
  }
}

connectButton.addEventListener('click', connectWallet)
transferForm.addEventListener('submit', transferTokens)

if (window.ethereum) {
  window.ethereum.on('accountsChanged', () => window.location.reload())
  window.ethereum.on('chainChanged', () => window.location.reload())
}