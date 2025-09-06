import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

const { ethers } = hre;

describe("MotoToken", function () {
  let motoToken, buyback, vault, liquidityLocker;
  let owner, addr1, addr2, addr3;
  let mockRouter;
  
  const TOTAL_SUPPLY = ethers.parseEther("1000000000"); // 1 billion tokens
  const BUYBACK_RATE = 2;
  const LIQUIDITY_RATE = 3;
  const TOTAL_FEE_RATE = BUYBACK_RATE + LIQUIDITY_RATE;
  
  async function deployContractsFixture() {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // Deploy MotoToken
    const MotoToken = await ethers.getContractFactory("MotoToken");
    const motoToken = await MotoToken.deploy(owner.address);
    await motoToken.waitForDeployment();

    return {
      motoToken,
      owner,
      addr1,
      addr2,
      addr3
    };
  }
  
  beforeEach(async function () {
    const fixture = await loadFixture(deployContractsFixture);
    motoToken = fixture.motoToken;
    buyback = fixture.buyback;
    vault = fixture.vault;
    liquidityLocker = fixture.liquidityLocker;
    mockRouter = fixture.mockRouter;
    owner = fixture.owner;
    addr1 = fixture.addr1;
    addr2 = fixture.addr2;
    addr3 = fixture.addr3;
  });
  
  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await motoToken.owner()).to.equal(owner.address);
    });
    
    it("Should assign the total supply to the owner", async function () {
      const ownerBalance = await motoToken.balanceOf(owner.address);
      expect(await motoToken.totalSupply()).to.equal(ownerBalance);
      expect(ownerBalance).to.equal(TOTAL_SUPPLY);
    });
    
    it("Should set correct token details", async function () {
      expect(await motoToken.name()).to.equal("Moto");
      expect(await motoToken.symbol()).to.equal("MOTO");
      expect(await motoToken.decimals()).to.equal(18);
    });
    
    it("Should set correct fee rates", async function () {
      expect(await motoToken.buybackRate()).to.equal(BUYBACK_RATE);
      expect(await motoToken.liquidityRate()).to.equal(LIQUIDITY_RATE);
      expect(await motoToken.getTotalFeeRate()).to.equal(TOTAL_FEE_RATE);
    });
  });
  
  describe("Fee Mechanism", function () {
    beforeEach(async function () {
      // Transfer some tokens to addr1 for testing
      await motoToken.transfer(addr1.address, ethers.parseEther("1000"));
    });
    
    it("Should apply fees on transfers between non-exempt addresses", async function () {
      const transferAmount = ethers.parseEther("100");
      const expectedFee = (transferAmount * BigInt(TOTAL_FEE_RATE)) / 100n;
      const expectedNetAmount = transferAmount - expectedFee;
      
      const initialBalance = await motoToken.balanceOf(addr2.address);
      
      await motoToken.connect(addr1).transfer(addr2.address, transferAmount);
      
      const finalBalance = await motoToken.balanceOf(addr2.address);
      expect(finalBalance - initialBalance).to.equal(expectedNetAmount);
    });
    
    it("Should not apply fees for exempt addresses", async function () {
      const transferAmount = ethers.parseEther("100");
      
      // Owner is exempt by default
      const initialBalance = await motoToken.balanceOf(addr1.address);
      await motoToken.transfer(addr1.address, transferAmount);
      const finalBalance = await motoToken.balanceOf(addr1.address);
      
      expect(finalBalance - initialBalance).to.equal(transferAmount);
    });
    
    it("Should distribute fees correctly to auxiliary contracts", async function () {
      const transferAmount = ethers.parseEther("100");
      const expectedFee = (transferAmount * BigInt(TOTAL_FEE_RATE)) / 100n;
      const expectedBuybackAmount = (expectedFee * BigInt(BUYBACK_RATE)) / BigInt(TOTAL_FEE_RATE);
      const expectedVaultAmount = expectedFee - expectedBuybackAmount;
      
      const buybackAddress = await buyback.getAddress();
      const vaultAddress = await vault.getAddress();
      
      const initialBuybackBalance = await motoToken.balanceOf(buybackAddress);
      const initialVaultBalance = await motoToken.balanceOf(vaultAddress);
      
      await motoToken.connect(addr1).transfer(addr2.address, transferAmount);
      
      const finalBuybackBalance = await motoToken.balanceOf(buybackAddress);
      const finalVaultBalance = await motoToken.balanceOf(vaultAddress);
      
      expect(finalBuybackBalance - initialBuybackBalance).to.equal(expectedBuybackAmount);
      expect(finalVaultBalance - initialVaultBalance).to.equal(expectedVaultAmount);
    });
  });
  
  describe("Fee Exemption", function () {
    it("Should allow owner to set fee exemption", async function () {
      await motoToken.setFeeExemption(addr1.address, true);
      expect(await motoToken.feeExempt(addr1.address)).to.be.true;
      
      await motoToken.setFeeExemption(addr1.address, false);
      expect(await motoToken.feeExempt(addr1.address)).to.be.false;
    });
    
    it("Should not allow non-owner to set fee exemption", async function () {
      await expect(
        motoToken.connect(addr1).setFeeExemption(addr2.address, true)
      ).to.be.revertedWithCustomError(motoToken, "OwnableUnauthorizedAccount");
    });
  });
  
  describe("Fee Rate Updates", function () {
    it("Should allow owner to update fee rates", async function () {
      const newBuybackRate = 3;
      const newLiquidityRate = 2;
      
      await motoToken.updateFeeRates(newBuybackRate, newLiquidityRate);
      
      expect(await motoToken.buybackRate()).to.equal(newBuybackRate);
      expect(await motoToken.liquidityRate()).to.equal(newLiquidityRate);
    });
    
    it("Should not allow fee rates exceeding maximum", async function () {
      await expect(
        motoToken.updateFeeRates(8, 5) // Total 13% > 10% max
      ).to.be.revertedWith("MotoToken: total fee exceeds maximum");
    });
    
    it("Should not allow non-owner to update fee rates", async function () {
      await expect(
        motoToken.connect(addr1).updateFeeRates(1, 1)
      ).to.be.revertedWithCustomError(motoToken, "OwnableUnauthorizedAccount");
    });
  });
  
  describe("Contract Configuration", function () {
    it("Should allow owner to set auxiliary contracts", async function () {
      const newBuyback = await buyback.getAddress();
      const newVault = await vault.getAddress();
      
      await motoToken.setContracts(newBuyback, newVault);
      
      expect(await motoToken.buybackContract()).to.equal(newBuyback);
      expect(await motoToken.vaultContract()).to.equal(newVault);
    });
    
    it("Should not allow setting zero addresses", async function () {
      await expect(
        motoToken.setContracts(ethers.ZeroAddress, await vault.getAddress())
      ).to.be.revertedWith("MotoToken: invalid buyback address");
      
      await expect(
        motoToken.setContracts(await buyback.getAddress(), ethers.ZeroAddress)
      ).to.be.revertedWith("MotoToken: invalid vault address");
    });
  });
  
  describe("Emergency Functions", function () {
    it("Should allow owner to recover stuck tokens", async function () {
      // Deploy a mock ERC20 token
      const MockToken = await ethers.getContractFactory("MotoToken");
      const mockToken = await MockToken.deploy(owner.address);
      await mockToken.waitForDeployment();
      
      // Send some mock tokens to MotoToken contract
      const amount = ethers.parseEther("100");
      await mockToken.transfer(await motoToken.getAddress(), amount);
      
      const initialOwnerBalance = await mockToken.balanceOf(owner.address);
      
      // Recover the tokens
      await motoToken.emergencyRecoverToken(await mockToken.getAddress(), amount);
      
      const finalOwnerBalance = await mockToken.balanceOf(owner.address);
      expect(finalOwnerBalance - initialOwnerBalance).to.equal(amount);
    });
    
    it("Should not allow recovering MOTO tokens", async function () {
      await expect(
        motoToken.emergencyRecoverToken(await motoToken.getAddress(), 100)
      ).to.be.revertedWith("MotoToken: cannot recover MOTO tokens");
    });
    
    it("Should allow owner to recover stuck ETH", async function () {
      // Send ETH to the contract
      await owner.sendTransaction({
        to: await motoToken.getAddress(),
        value: ethers.parseEther("1")
      });
      
      const initialOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      // Recover ETH
      const tx = await motoToken.emergencyRecoverETH();
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      
      const finalOwnerBalance = await ethers.provider.getBalance(owner.address);
      const expectedBalance = initialOwnerBalance + ethers.parseEther("1") - gasUsed;
      
      expect(finalOwnerBalance).to.be.closeTo(expectedBalance, ethers.parseEther("0.01"));
    });
  });
  
  describe("Fee Calculation", function () {
    it("Should calculate fees correctly", async function () {
      const amount = ethers.parseEther("1000");
      const [feeAmount, netAmount] = await motoToken.calculateFee(amount);
      
      const expectedFee = (amount * BigInt(TOTAL_FEE_RATE)) / 100n;
      const expectedNet = amount - expectedFee;
      
      expect(feeAmount).to.equal(expectedFee);
      expect(netAmount).to.equal(expectedNet);
    });
  });
});