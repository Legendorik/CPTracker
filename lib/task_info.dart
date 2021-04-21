class TaskInfo {

  int state; //TODO possible values check
  String description;
  DateTime deadline;

  TaskInfo(this.state){
    description = "";
    deadline = null;
  }

  TaskInfo.full(this.state, this.description, this.deadline);

}