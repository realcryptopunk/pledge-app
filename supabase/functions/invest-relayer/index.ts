import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { ethers } from "npm:ethers@6";

// MARK: - CORS Headers

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Authorization, Content-Type, apikey, x-client-info",
};

// MARK: - Contract Addresses (Arbitrum Sepolia)

const PLEDGE_VAULT_ADDRESS = "0xb7DdF629007C2A489C254eea3726750235B82178";
const USDC_ADDRESS = "0x9cA75917e9c158569a602cb2504823282fb4Fc45";
const DEFAULT_RPC_URL = "https://sepolia-rollup.arbitrum.io/rpc";
const EXPLORER_BASE = "https://sepolia.arbiscan.io";

// MARK: - Minimal ABIs

const VAULT_ABI = [
  "function register(uint8 tier) external",
  "function deposit(uint256 amount) external returns (uint256)",
  "function investOnFailure(uint256 pledgeId, uint256 usdyMinOut, uint256 bcspxMinOut) external",
];

const ERC20_ABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function decimals() view returns (uint8)",
];

// MARK: - Input Validation

const ETH_ADDRESS_REGEX = /^0x[0-9a-fA-F]{40}$/;
const MAX_USDC_AMOUNT = 1000; // Testnet safety cap
const VALID_RISK_TIERS = [0, 1, 2]; // 0=LOW, 1=MEDIUM, 2=HIGH

function validateInput(body: {
  user_wallet?: string;
  usdc_amount?: number;
  risk_tier?: number;
}): { user_wallet: string; usdc_amount: number; risk_tier: number } | Response {
  const { user_wallet, usdc_amount, risk_tier } = body;

  if (!user_wallet || typeof user_wallet !== "string") {
    return new Response(
      JSON.stringify({ error: "Missing or invalid user_wallet" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (!ETH_ADDRESS_REGEX.test(user_wallet)) {
    return new Response(
      JSON.stringify({
        error:
          "Invalid user_wallet — must be a valid Ethereum address (0x + 40 hex chars)",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (usdc_amount === undefined || typeof usdc_amount !== "number") {
    return new Response(
      JSON.stringify({ error: "Missing or invalid usdc_amount" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (usdc_amount <= 0) {
    return new Response(
      JSON.stringify({
        error: "Invalid usdc_amount — must be a positive number",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (usdc_amount > MAX_USDC_AMOUNT) {
    return new Response(
      JSON.stringify({
        error: `usdc_amount exceeds testnet safety cap of ${MAX_USDC_AMOUNT} USDC`,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const tier = risk_tier ?? 1; // Default to MEDIUM
  if (!VALID_RISK_TIERS.includes(tier)) {
    return new Response(
      JSON.stringify({
        error: "Invalid risk_tier — must be 0 (LOW), 1 (MEDIUM), or 2 (HIGH)",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  return { user_wallet, usdc_amount, risk_tier: tier };
}

// MARK: - Main Handler

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Only allow POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    // Parse and validate input
    const body = await req.json();
    const validated = validateInput(body);
    if (validated instanceof Response) {
      return validated;
    }
    const { user_wallet, usdc_amount, risk_tier } = validated;

    // Load environment variables
    const relayerPrivateKey = Deno.env.get("RELAYER_PRIVATE_KEY");
    if (!relayerPrivateKey) {
      console.error("RELAYER_PRIVATE_KEY is not set");
      return new Response(
        JSON.stringify({
          error:
            "Server configuration error: RELAYER_PRIVATE_KEY is not set",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const rpcUrl =
      Deno.env.get("ARBITRUM_SEPOLIA_RPC_URL") || DEFAULT_RPC_URL;

    // Set up ethers provider and signer
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(relayerPrivateKey, provider);

    // Query USDC decimals from contract (with fallback)
    const usdc = new ethers.Contract(USDC_ADDRESS, ERC20_ABI, wallet);
    let decimals = 18;
    try {
      decimals = Number(await usdc.decimals());
    } catch (err) {
      console.warn(
        "Failed to query USDC decimals, defaulting to 18:",
        err instanceof Error ? err.message : String(err)
      );
    }

    // Convert human-readable USDC amount to on-chain units
    const parsedAmount = ethers.parseUnits(
      usdc_amount.toString(),
      decimals
    );

    // Create vault contract instance
    const vault = new ethers.Contract(
      PLEDGE_VAULT_ADDRESS,
      VAULT_ABI,
      wallet
    );

    // Step 1: Register relayer's risk tier
    console.log(`Step 1: register(tier=${risk_tier})`);
    const registerTx = await vault.register(risk_tier);
    await registerTx.wait(1);
    console.log(`Register confirmed: ${registerTx.hash}`);

    // Step 2: Approve USDC to vault
    console.log(`Step 2: approve(vault, ${parsedAmount.toString()})`);
    const approveTx = await usdc.approve(PLEDGE_VAULT_ADDRESS, parsedAmount);
    await approveTx.wait(1);
    console.log(`Approve confirmed: ${approveTx.hash}`);

    // Step 3: Deposit USDC into vault — capture pledgeId from return value
    console.log(`Step 3: deposit(${parsedAmount.toString()})`);
    const depositTx = await vault.deposit(parsedAmount);
    const depositReceipt = await depositTx.wait(1);
    console.log(`Deposit confirmed: ${depositTx.hash}`);

    // Extract pledgeId from deposit return value via static call
    let pledgeId: bigint;
    try {
      pledgeId = await vault.deposit.staticCall(parsedAmount);
    } catch {
      // Fallback: parse from deposit logs or use 0
      // The pledgeId is typically emitted in an event; for now use the tx index approach
      console.warn("Static call for pledgeId failed, using log-based extraction");
      // Try to get pledgeId from deposit receipt logs
      const depositEvent = depositReceipt.logs[depositReceipt.logs.length - 1];
      if (depositEvent && depositEvent.data) {
        pledgeId = BigInt(depositEvent.data);
      } else {
        pledgeId = BigInt(0);
      }
    }
    console.log(`PledgeId: ${pledgeId.toString()}`);

    // Step 4: Invest on failure (0 minOut for testnet)
    console.log(`Step 4: investOnFailure(${pledgeId.toString()}, 0, 0)`);
    const investTx = await vault.investOnFailure(pledgeId, 0, 0);
    const investReceipt = await investTx.wait(1);
    console.log(
      `investOnFailure confirmed in block ${investReceipt.blockNumber}: ${investReceipt.hash}`
    );

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        tx_hash: investReceipt.hash,
        explorer_url: `${EXPLORER_BASE}/tx/${investReceipt.hash}`,
        pledge_id: pledgeId.toString(),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("invest-relayer error:", err);

    // Extract revert reason if available
    const message =
      err instanceof Error ? err.message : String(err);

    // Check if this is a contract revert
    const isRevert =
      message.includes("revert") ||
      message.includes("CALL_EXCEPTION") ||
      message.includes("execution reverted");

    // Check if this is an RPC connection error
    const isRpcError =
      message.includes("could not detect network") ||
      message.includes("NETWORK_ERROR") ||
      message.includes("SERVER_ERROR") ||
      message.includes("TIMEOUT");

    const statusCode = isRevert || isRpcError ? 502 : 500;

    return new Response(
      JSON.stringify({
        error: isRevert
          ? "Transaction reverted"
          : isRpcError
          ? "RPC connection error"
          : "Internal server error",
        message: message,
      }),
      {
        status: statusCode,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
