AQoLVehicleRepair = AQoLVehicleRepair or {}

AQoLVehicleRepair.Config = {
    RepairAmountBonusPerLevel = 0.02,
    IgnoreRepairCountPerLevel = 0.05,
    IgnoreRepairCountMax = 0.75,
    BaseMissingConditionFraction = 0.20,
    MinimumRepairAmount = 1,
}

-- Verified vanilla InventoryItems in the Brake/Suspension/Muffler/Tire templates.
-- Exact names only: never opt another mod's vehicle parts into these recipes.
AQoLVehicleRepair.Targets = {}
for _, stem in ipairs({
    "OldBrake", "NormalBrake", "ModernBrake",
    "NormalSuspension", "ModernSuspension",
    "OldCarMuffler", "NormalCarMuffler", "ModernCarMuffler",
    "OldTire", "NormalTire", "ModernTire",
}) do
    for vehicleType = 1, 3 do
        AQoLVehicleRepair.Targets["Base." .. stem .. vehicleType] = true
    end
end
