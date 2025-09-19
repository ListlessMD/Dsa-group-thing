import ballerina/time;
import ballerina/http;

public type Asset record {|
	readonly string AssetTag;
	string Name;
	string Faculty;
	string Department;
	time:Date acquiredDate;
	Status currentStatus;
|};

public type equipment Asset;
public type servers Asset;

public type laboratory Asset;

public type vehicles Asset;

public enum Status {
    ACTIVE,
    UNDER_REPAIR,
    DISPOSED
}

service /assets on new http:Listener(8080) {

    resource function post .(Asset newAsset) returns string {
        // Logic to add the new asset to the database
        return "Asset added successfully";
    }

}

public type Component record {|
    string id;
    string name;
    string description?;
|};

public type MaintenanceSchedule record {|
    string frequency; // e.g., "Quarterly", "Yearly"
    time:Date nextDueDate;
|};

public type Task record {|
    string id;
    string description;
    boolean completed;
|};

public type WorkOrder record {|
    string id;
    string issueDescription;
    time:Date openedDate;
    Status status;
    Task[] tasks;
|};

public type AssetDetails record {|
    Asset assetInfo;
    Component[] components;
    MaintenanceSchedule[] maintenanceSchedules;
    WorkOrder[] workOrders;
|};