import ballerina/http;
import ballerina/time;
import ballerina/uuid;



type Assets record {|
    string AssetTag;
    string name;
    string faculty;
    string department;
    string status;
    time:Date acquiredDate;
    map<component> components;
    map<maintainance_schedule> maintainanceSchedules;
    map<workorder> workOrders;

|};

type component record {|
string id;
string Name;
string description;
string serialNumber;

  |};

type maintainance_schedule record {|
string id;
string status;
string scheduleType;
time:Date nextDueDate;
string description;|};

type task record{
string id;
string description;
string status;
time:Utc openedDate;
time:Utc completedDate;
};

type workorder record {|
 string id;
 string status;
string description;
string title;
string workorderstatus;
time:Utc openedDate;
time:Utc completedDate;
  map<task> tasks;
|};


final map<Assets> assetDB = {};

service /equipserve on new http:Listener(8080) {

    resource function get assets() returns json|error {
        return <json>assetDB;
    }

    resource function get assets/[string assetTag]() returns Assets|error {
        if assetDB.hasKey(assetTag) {
            return <Assets>assetDB[assetTag];
        } else {
            return error("Asset not found");
        }
    }

    resource function post assets(Assets newAsset) returns string|error {

        if newAsset.AssetTag is string && newAsset.AssetTag.length()==0{
            
            newAsset.AssetTag  =
            uuid:createRandomUuid();

        }
        
        if assetDB.hasKey(newAsset.AssetTag) {
            return error("Asset with this tag already exists");
        } else {
            assetDB[newAsset.AssetTag] = newAsset;
            return "Asset added successfully";
        }
    }

    resource function put assets/[string assetTag](Assets updatedAsset) returns string|error {
        if assetDB.hasKey(assetTag) {
            assetDB[assetTag] = updatedAsset;
            return "Asset updated successfully";
        } else {
            return error("Asset not found");
        }
    }

    resource function delete assets/[string assetTag]() returns string|error {
        if assetDB.hasKey(assetTag) {
            _ = assetDB.remove(assetTag);
            return "Asset deleted successfully";
        } else {
            return error("Asset not found");
        }
    }
    resource   function get faculty(string faculty) returns Assets[] {
        return assetDB.toArray().filter(Assets=>Assets.faculty==  faculty);
        }


    resource function get maintainance_schedule/Overdue() returns maintainance_schedule[] {
    maintainance_schedule[] overdueSchedules = [];

    // Get today's civil date
    time:Utc nowEpoch = time:utcNow();
    time:Civil currentDate = time:utcToCivil(nowEpoch);

    foreach var [_, asset] in assetDB.entries() {
        foreach var [_, sched] in asset.maintainanceSchedules.entries() {
            time:Date dueDate = sched.nextDueDate;

            // Simple overdue check by comparing fields
            boolean isOverdue = dueDate.year < currentDate.year ||
                                (dueDate.year == currentDate.year && dueDate.month < currentDate.month) ||
                                (dueDate.year == currentDate.year && dueDate.month == currentDate.month && dueDate.day < currentDate.day);

            if isOverdue {
                overdueSchedules.push(sched);
            }
        }
    }

    return overdueSchedules;
}

resource function post [string assetTag]/components(component comp) returns component|http:NotFound {
    if !assetDB.hasKey(assetTag) {
        return http:NOT_FOUND;
    }

    component newComponent = comp.cloneReadOnly();
    newComponent.id = uuid:createRandomUuid();

    assetDB[assetTag].components[check newComponent.id] = newComponent;

    return newComponent;
}

 resource function delete [string assetTag]/components/[string componentId]() returns http:Ok|http:NotFound {
        Assets? asset = assetDB[assetTag];
        if asset is Assets {
            if asset.components.hasKey(componentId) {
                _ = asset.components.remove(componentId);
                assetDB[assetTag] = asset;
                return http:OK;
            }
            return http:NOT_FOUND;
        }
        return http:NOT_FOUND;
    }
resource function post [string assetTag]/maintainanceSchedules(maintainance_schedule schedule)
        returns maintainance_schedule|http:NotFound {

    Assets? asset = assetDB[assetTag];
    if asset is Assets {
       maintainance_schedule newSchedule = schedule.cloneReadOnly();
        newSchedule.id = uuid:createRandomUuid();

        // Add to the map using the new id as key
        asset.maintainanceSchedules[newSchedule.id] = newSchedule;

        // Save back to the DB
        assetDB[assetTag] = asset;

        return newSchedule;
    }

    return http:NOT_FOUND;
}

resource function delete [string assetTag]/maintainanceSchedules/[string scheduleId]()
        returns http:Ok|http:NotFound {

    // Get the asset safely
    Assets? asset = assetDB[assetTag];
    if asset is Assets {
        if asset.maintainanceSchedules.hasKey(scheduleId) {
            _ = asset.maintainanceSchedules.remove(scheduleId);
            // Save back to the DB
            assetDB[assetTag] = asset;
            return http:OK;
        }
        return http:NOT_FOUND;
    }
    return http:NOT_FOUND;
}

resource function post [string assetTag]/workorders(workorder wrk)
        returns workorder|http:NotFound {

    Assets? asset = assetDB[assetTag];
    if asset is Assets {
        workorder newWorkOrder = wrk.cloneReadOnly();
        newWorkOrder.id = uuid:createRandomUuid();

        // Add to the map using id as key
        asset.workOrders[newWorkOrder.id] = newWorkOrder;

        // Update asset status if not UNDER_REPAIR
        if asset.status != "UNDER_REPAIR" {
            asset.status = "UNDER_REPAIR";
        }

        // Save back to DB
        assetDB[assetTag] = asset;

        return newWorkOrder;
    }

    return http:NOT_FOUND;
}

resource function put [string assetTag]/workorders/[string workOrderId](workorder wrk)
        returns workorder|http:NotFound {

    Assets? asset = assetDB[assetTag];
    if asset is Assets {
        if asset.workOrders.hasKey(workOrderId) {
            // Clone parameter to avoid mutating input directly
            workorder updatedWorkOrder = wrk.cloneReadOnly();
            updatedWorkOrder.id = workOrderId;

            // Save back to the asset map
            asset.workOrders[workOrderId] = updatedWorkOrder;

            // If status is ACTIVE or DISPOSED, mark completed date
            if updatedWorkOrder.workorderstatus == "ACTIVE" ||
               updatedWorkOrder.status == "DISPOSED" {
                updatedWorkOrder.completedDate = time:utcNow();
                asset.workOrders[workOrderId] = updatedWorkOrder; // update again
            }

            // Save back to DB
            assetDB[assetTag] = asset;

            return updatedWorkOrder;
        }

        return http:NOT_FOUND;
    }

    return http:NOT_FOUND;
}

resource function delete [string assetTag]/workorders/[string workOrderId]()
        returns http:Ok|http:NotFound {

    // Get the asset safely
    Assets? asset = assetDB[assetTag];
    if asset is Assets {
        // Check if the work order exists
        if asset.workOrders.hasKey(workOrderId) {
            _ = asset.workOrders.remove(workOrderId);
            // Save back to DB
            assetDB[assetTag] = asset;
            return http:OK;
        }
        return http:NOT_FOUND;
    }

    return http:NOT_FOUND;
}
 resource function post [string assetTag]/workorders/[string workOrderId]/tasks(task tsk)
        returns task|http:NotFound {

        Assets? asset = assetDB[assetTag];
        if asset is Assets {
            if asset.workOrders.hasKey(workOrderId) {
                task newTask = tsk.cloneReadOnly();
                newTask.id = uuid:createRandomUuid();
                newTask.openedDate = time:utcNow();
                asset.workOrders[workOrderId].tasks[newTask.id] = newTask;
                assetDB[assetTag] = asset;
                return newTask;
            }
            return http:NOT_FOUND;
        }
        return http:NOT_FOUND;
    }

   function checkAndUpdateAssetStatus(string assetTag) {
    Assets? asset = assetDB[assetTag];
    if asset is Assets {
        boolean hasActiveWorkOrders = false;

        foreach var [_ , wo] in asset.workOrders.entries() {
            if wo.status == "UNDER_REPAIR" {
                hasActiveWorkOrders = true;
                break;
            }
        }

        if !hasActiveWorkOrders && asset.status == "UNDER_REPAIR" {
            asset.status = "ACTIVE";
            assetDB[assetTag] = asset;
        }
    }
   }

}








