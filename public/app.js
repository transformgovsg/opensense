(() => {
    const packageName = "@govtechsg/sgds-web-component";
    const version = "1.1.0";
    const webComponentScriptUrl = "https://cdn.jsdelivr.net/npm/" + packageName + "@" + version + "/components/Masthead/index.umd.js";

    const addGovSgBanner = () => {

        const script = document.createElement("script");
        script.type = "module";
        script.src = webComponentScriptUrl;
        script.onload = function () {
            const masthead = document.createElement("sgds-masthead");
            document.body.insertBefore(masthead, document.body.firstChild);
        };
        document.head.appendChild(script);
    };

    const reducePageHeight = () => {
        const link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('href', '/public/reduce-height-for-masthead.css');
        document.head.appendChild(link);
    };

    document.addEventListener("DOMContentLoaded", function () {
        const currentUrl = window.location;
        const isGovSgDomain = currentUrl.hostname.endsWith('.gov.sg');
        if (isGovSgDomain) {
            addGovSgBanner();
            reducePageHeight();
        }
    });
})();