import React from "react";

import ModelSelector from "../model-selector";
import UpdateChecker from "../update-checker";

const Footer: React.FC = () => {
  return (
    <div className="w-full border-t border-mid-gray/20 pt-3">
      <div className="flex justify-between items-center text-xs px-4 pb-3 text-text/60">
        <div className="flex items-center gap-4">
          <ModelSelector />
        </div>

        {/* Update Status (UpdateChecker shows the version + how far behind upstream) */}
        <div className="flex items-center gap-1">
          <UpdateChecker />
        </div>
      </div>
    </div>
  );
};

export default Footer;
