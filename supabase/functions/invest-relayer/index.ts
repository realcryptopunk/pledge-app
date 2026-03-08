import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { ethers } from "npm:ethers@6";

// MARK: - CORS Headers

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Authorization, Content-Type, apikey, x-client-info",
};

// MARK: - Contract Addresses (RH Chain Testnet)

const PLEDGE_VAULT_ADDRESS = "0x70d73b04d0c2ee4f73eb44cbf5377a2c3fbc52ba";
const USDC_ADDRESS = "0xbf4479C07Dc6fdc6dAa764A0ccA06969e894275F";
const DEFAULT_RPC_URL = "https://rpc.testnet.chain.robinhood.com";
const EXPLORER_BASE = "https://explorer.testnet.chain.robinhood.com";

// MARK: - Minimal ABIs

const VAULT_ABI = [
  "function investForUser(address user, uint256 usdcAmount) external",
];

const ERC20_ABI = ["function decimals() view returns (uint8)"];

// MARK: - Input Validation

const ETH_ADDRESS_REGEX = /^0x[0-9a-fA-F]{40}$/;
const MAX_USDC_AMOUNT = 1000; // Testnet safety cap

function validateInput(body: {
  user_wallet?: string;
  usdc_amount?: number;
}): { user_wallet: string; usdc_amount: number } | Response {
  const { user_wallet, usdc_amount } = body;

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

  return { user_wallet, usdc_amount };
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
    const { user_wallet, usdc_amount } = validated;

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
      Deno.env.get("RH_TESTNET_RPC_URL") || DEFAULT_RPC_URL;

    // Set up ethers provider and signer
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(relayerPrivateKey, provider);

    // Query USDC decimals from contract (with fallback)
    let decimals = 18;
    try {
      const usdcContract = new ethers.Contract(
        USDC_ADDRESS,
        ERC20_ABI,
        provider
      );
      decimals = Number(await usdcContract.decimals());
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

    // Create vault contract instance and call investForUser
    const vault = new ethers.Contract(
      PLEDGE_VAULT_ADDRESS,
      VAULT_ABI,
      wallet
    );

    console.log(
      `Calling investForUser(${user_wallet}, ${parsedAmount.toString()}) with decimals=${decimals}`
    );

    const tx = await vault.investForUser(user_wallet, parsedAmount);
    console.log(`Transaction submitted: ${tx.hash}`);

    // Wait for 1 confirmation
    const receipt = await tx.wait(1);
    console.log(
      `Transaction confirmed in block ${receipt.blockNumber}`
    );

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        tx_hash: receipt.hash,
        explorer_url: `${EXPLORER_BASE}/tx/${receipt.hash}`,
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
