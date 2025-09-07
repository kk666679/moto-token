import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

const { ethers } = hre;

describe("Buyback", function () {
  async function deployFixture() {
    const [owner, addr1] = await ethers.getSigners();

    const MotoToken = await ethers.getContractFactory("MotoToken");
    const motoToken = await MotoToken.deploy(owner.address);

    const MockRouter = await ethers.getContractFactory("MockUniswapV2Router");
    const mockRouter = await MockRouter.deploy();

    const Buyback = await ethers.getContractFactory("Buyback");
    const buyback = await Buyback.deploy(
      await motoToken.getAddress(),
      await mockRouter.getAddress(),
      owner.address
    );

    return { motoToken, buyback, mockRouter, owner, addr1 };
  }

  describe("Deployment", function () {
    it("Should set correct initial values", async function () {
      const { buyback, motoToken, mockRouter, owner } = await loadFixture(deployFixture);
      
      expect(await buyback.motoToken()).to.equal(await motoToken.getAddress());
      expect(await buyback.router()).to.equal(await mockRouter.getAddress());
      expect(await buyback.owner()).to.equal(owner.address);
    });
  });

  describe("Configuration", function () {
    it("Should allow owner to update minimum tokens", async function () {
      const { buyback } = await loadFixture(deployFixture);
      
      await buyback.updateMinTokensForBuyback(ethers.parseEther("2000"));
      expect(await buyback.minTokensForBuyback()).to.equal(ethers.parseEther("2000"));
    });

    it("Should allow owner to update max slippage", async function () {
      const { buyback } = await loadFixture(deployFixture);
      
      await buyback.updateMaxSlippage(1000); // 10%
      expect(await buyback.maxSlippage()).to.equal(1000);
    });

    it("Should reject slippage above 20%", async function () {
      const { buyback } = await loadFixture(deployFixture);
      
      await expect(buyback.updateMaxSlippage(2500))
        .to.be.revertedWith("Buyback: slippage too high");
    });
  });
});