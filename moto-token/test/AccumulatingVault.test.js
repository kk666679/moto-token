import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

const { ethers } = hre;

describe("AccumulatingVault", function () {
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const MotoToken = await ethers.getContractFactory("MotoToken");
    const motoToken = await MotoToken.deploy(owner.address);

    const MockRouter = await ethers.getContractFactory("MockUniswapV2Router");
    const mockRouter = await MockRouter.deploy();

    const AccumulatingVault = await ethers.getContractFactory("AccumulatingVault");
    const vault = await AccumulatingVault.deploy(
      await motoToken.getAddress(),
      await mockRouter.getAddress(),
      owner.address
    );

    return { motoToken, vault, mockRouter, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should set correct initial values", async function () {
      const { vault, motoToken, mockRouter, owner } = await loadFixture(deployFixture);
      
      expect(await vault.motoToken()).to.equal(await motoToken.getAddress());
      expect(await vault.router()).to.equal(await mockRouter.getAddress());
      expect(await vault.owner()).to.equal(owner.address);
      expect(await vault.rewardPercentage()).to.equal(60);
      expect(await vault.liquidityPercentage()).to.equal(40);
    });
  });

  describe("Configuration", function () {
    it("Should allow owner to update percentages", async function () {
      const { vault } = await loadFixture(deployFixture);
      
      await vault.updatePercentages(70, 30);
      expect(await vault.rewardPercentage()).to.equal(70);
      expect(await vault.liquidityPercentage()).to.equal(30);
    });

    it("Should reject percentages that don't sum to 100", async function () {
      const { vault } = await loadFixture(deployFixture);
      
      await expect(vault.updatePercentages(70, 40))
        .to.be.revertedWith("AccumulatingVault: percentages must sum to 100");
    });
  });
});