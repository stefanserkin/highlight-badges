/**
 * From Mario Pavicic and Salesforce Labs
 * https://bootcamp.uxdesign.cc/mastering-salesforce-ui-confetti-ff8e0b945dce
 * 
 * Modified by SerkinSolutions to simplify and remove emoji support
 */
import { LightningElement, api } from 'lwc';
import { JSConfetti } from './js-confetti';

export default class Confetti extends LightningElement {
    @api size = 'medium';
    @api number = 'normal';
    @api type = 'default';

    sizeOptions = [
        { label: 'small', value: 60 },
        { label: 'medium', value: 100 },
        { label: 'large', value: 140 }
    ];
    numberOptions = [
        { label: 'few', value: 15 },
        { label: 'normal', value: 30 },
        { label: 'plenty', value: 50 }
    ];

    renderedCallback() {
        // Confetti will be shown immediately when component renders
        const jsConfetti = new JSConfetti({});
        jsConfetti.addConfetti({
            confettiNumber: this.numberOptions.filter(o => o.label === this.number)[0].value * 4,
        });
    }
}