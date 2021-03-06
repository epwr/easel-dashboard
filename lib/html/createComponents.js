/* createComponent.js
 *
 * Author: Eric Power
 *
 * Description:
 *    Provides two main functions: create_dashboard and create_command_output.
 *    These functions are called to create a Node for each dashboard, and one
 *    shared Node for the outputs of each command.
 */
/* Longer-term Refactor Plan
 *
 *    - Actually commit to the OOP concept. Move all dashboards into one list,
 *      so all IDs are numbers. Then all massages are ID:MESSAGE and the MESSAGE
 *      is passed to dashboard.processMessage(MESSAGE). Allow graphic and text
 *      dashboards to be subclasses of a Dashboard class with .load(), defined
 *      there.
 *          Question: how to handle multiple objects sending over websocket.
 */

"use strict";

class GraphicDashboard {

  constructor(name, desc, elements, size) {

      this.node = document.createElement("div");
      this.node.className = "dashboard";
      this.initialized = false;
      this.elementInfo = elements;
      this.elements = [];
      this.storedData = [];
      this.storedLabels = [];



      // Build header and add to dashbaord.
      let header = document.createElement("div");
      let title = document.createElement("h2");
      let description = document.createElement("span");
      header.className = "dashboard-title-wrapper"
      title.innerHTML = name;
      description.innerHTML = desc;
      header.appendChild(title);
      header.appendChild(description);
      this.node.appendChild(header);

      // Build the display (cwithout the elements).
      this.display = document.createElement("div");
      this.display.className = "dashboard-main-graphics"
      this.node.appendChild(this.display);

      // Build Footer
      let footer = document.createElement("div");
      footer.className = "dashboard-footer";
      let shadow = document.createElement("div");
      shadow.className = "top-shadow";
      let buttonOne = document.createElement("div");
      buttonOne.className = "dashboard-button";
      buttonOne.onclick = () => {this.setContent("This help message is not yet implemented.")}
      buttonOne.innerHTML = "Help";
      let buttonTwo = document.createElement("div");
      buttonTwo.className = "dashboard-button";
      buttonTwo.onclick = () => {this.setContent("The 'Save Output' functionality is not yet implemented.")}
      buttonTwo.innerHTML = "Save Output";
      let buttonThree = document.createElement("div");
      buttonThree.className = "dashboard-button";
      buttonThree.onclick = () => {this.setContent("The 'Kill Server' command is not yet implemented.")}
      buttonThree.innerHTML = "Kill Server";
      footer.appendChild(shadow);
      footer.appendChild(buttonOne);
      footer.appendChild(buttonTwo);
      footer.appendChild(buttonThree);
      this.node.appendChild(footer);
  }

  update() {
    this.elements.forEach((element, index) => {
      this.display.removeChild(element.node);
    });
    this.elements.forEach((element, index) => {
      this.display.appendChild(element.node);
    });
  }

  load() {
    let root = document.getElementById('dashboard-wrapper');
    while( root.children.length > 0) root.removeChild(root.children[0]);
    root.appendChild(this.node);

    if (!this.initialized){
      this.elementInfo.forEach((elemInfo, index) => { // TODO: test removing index

        // TODO: rename createElement to aviod confusion with document.createElement
        let elem = createElement(elemInfo['type'], elemInfo['name'], elemInfo['desc'], elemInfo['dataTypes'], 2);
        this.display.appendChild(elem.node);
        this.elements.push(elem);
        this.initialized = true;

        // Add in storedData
        this.storedData.forEach((elementDataStore, i) => {
          let element = this.elements[i];
          elementDataStore.forEach((data, dataType) => {
            element.chart.data.datasets[dataType].data.push(data);
          });
          this.storedLabels[i].forEach((label, i) => {
            element.chart.data.labels.push(label);
          });
        });
      });
    }

    if (this.display.children[0].height == 0) {
      this.update(); // TODO: do we need to set loading, check again in 1 second?
    }
    this.elements.forEach((element, index) => {
      element.chart.update();
    });
  }

  addData(elem_id, dataType, label, value) {

    if (this.initialized) {
      let elem = this.elements[elem_id];
      const data = elem.chart.data;
      if (dataType == 0) { // Add a label from the 0th data type
        data.labels.push(label);
      }
      data.datasets[dataType].data.push(value); // push another data point
      elem.chart.update();
    } else {
      if (this.storedData[elem_id] == null) {
        this.storedData[elem_id] = [];
      }
      let dataStore = this.storedData[elem_id];
      if (dataStore[dataType] == null)
        dataStore[dataType] = [];
      dataStore[dataType].push(value);
      if (dataType == 0) {
        if (this.storedLabels[elem_id] == null)
          this.storedLabels[elem_id] = [];
        this.storedLabels[elem_id].push(label);
      }
    }
  }
}

class TextDashboard {

  constructor(name, desc, default_contents) {

      this.name = name;
      this.desc = desc;
      this.content = "";
      this.isRunning = false;
      this.node = document.createElement("div");
      this.node.className = "dashboard";

      // Build header
      let header = document.createElement("div");
      this.title = document.createElement("h2");
      this.description = document.createElement("span");
      header.className = "dashboard-title-wrapper"
      this.title.innerHTML = name;
      this.description.innerHTML = desc;
      header.appendChild(this.title);
      header.appendChild(this.description);
      this.node.appendChild(header);

      // Build Output Display
      let display = document.createElement("div");
      display.className = "dashboard-main-text scroll-content";
      this.preNode = document.createElement("pre");
      this.preNode.className = "dashboard-text-output";
      this.preNode.innerHTML = default_contents;
      display.appendChild(this.preNode);
      this.node.appendChild(display);

      // Build Footer
      let footer = document.createElement("div");
      footer.className = "dashboard-footer";
      let shadow = document.createElement("div");
      shadow.className = "top-shadow";
      let buttonOne = document.createElement("div");
      buttonOne.className = "dashboard-button";
      buttonOne.onclick = () => {this.setContent("This help message is not yet implemented.")}
      buttonOne.innerHTML = "Help";
      let buttonTwo = document.createElement("div");
      buttonTwo.className = "dashboard-button";
      buttonTwo.onclick = () => {this.setContent("The 'Save Output' functionality is not yet implemented.")}
      buttonTwo.innerHTML = "Save Output";
      let buttonThree = document.createElement("div");
      buttonThree.className = "dashboard-button";
      buttonThree.onclick = () => {this.setContent("The 'Kill Server' command is not yet implemented.")}
      buttonThree.innerHTML = "Kill Server";
      footer.appendChild(shadow);
      footer.appendChild(buttonOne);
      footer.appendChild(buttonTwo);
      footer.appendChild(buttonThree);
      this.node.appendChild(footer);
  }

  appendContent(newContent) {
    console.log("Before Appending: " + this.content);
    this.content += newContent;
    this.preNode.innerHTML = this.content;
    console.log("After Appending: " + this.content);
  }

  toggleRunning(){
    if( this.isRunning ){
        this.description.innerHTML = "Stopped";
        this.isRunning = false;
    } else {
      this.description.innerHTML = "Running";
      this.isRunning = false;
      this.clearContent();
      this.load();
    }
  }

  setIsRunning(state) {
    this.isRunning = state;
  }

  clearContent(){
    this.content = "";
    this.preNode.innerHTML = this.content;
  }

  load() {
    let root = document.getElementById('dashboard-wrapper');
    while( root.children.length > 0) root.removeChild(root.children[0]);
    root.appendChild(this.node);
  }
}
