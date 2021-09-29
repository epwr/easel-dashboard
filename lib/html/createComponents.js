/* createComponent.js
 *
 * Author: Eric Power
 *
 * Description:
 *    Provides two main functions: create_dashboard and create_command_output.
 *    These functions are called to create a Node for each dashboard, and one
 *    shared Node for the outputs of each command.
 */
"use strict";

class GraphicDashboard {

  constructor(name, desc, elements) {

      this.node = document.createElement("div");
      this.node.className = "dashboard";

      // Build header and add to dashbaord.
      let header = document.createElement("div");
      let title = document.createElement("h2");
      let description = document.createElement("span");
      header.className = "dashboard-title-wrapper" // TODO: implement or remove.
      title.innerHTML = name;
      description.innerHTML = desc;
      header.appendChild(title);
      header.appendChild(description);
      this.node.appendChild(header);

      // Build the display (contains the elements).
      this.display = document.createElement("div");
      this.display.className = "dashboard-main"
      this.elements = [];
      elements.forEach((element, index) => { // TODO: test removing index
        let elem = createElement(element['type'], element['name'], element['desc'], element['dataTypes']);
        this.elements.push(elem);
        this.display.appendChild(elem.node);
      });
      this.node.appendChild(this.display);

      // Build the footer.
      let footer = document.createElement("div");
      footer.innerHTML = "This is a footer";
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
}

class TextDashboard {

  constructor(name, desc, contents) {

      this.node = document.createElement("div");
      this.node.className = "dashboard";

      // Build header
      let header = document.createElement("div");
      this.title = document.createElement("h2");
      this.description = document.createElement("span");
      header.class = "dashboard-title-wrapper" // TODO: implement or remove.
      this.title.innerHTML = name;
      description.innerHTML = desc;
      header.appendChild(title);
      header.appendChild(description);
      this.node.appendChild(header);

      // Build Output Display
      let display = document.createElement("div");
      display.className = "dashboard-main scroll-content dashboard-inset-display";
      this.preNode = document.createElement("pre");
      this.preNode.className = "dashboard-text-output";
      this.preNode.innerHTML = contents;
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

  setTitle(title) {
    this.title = title;
  }

  setDescription(description) {
    this.description = description;
  }

  setContent(content) {
    this.content = content;
  }

  updateToCommand(command) {
    this.setTitle(command['name']);
    this.setDescription(command['desc']);
    this.setContent(command['output']);
  }
}
